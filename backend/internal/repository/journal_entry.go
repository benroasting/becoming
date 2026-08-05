package repository

import (
	"context"
	"errors"

	"github.com/benroasting/becoming/internal/models"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type JournalEntryRepository struct {
	pool *pgxpool.Pool
}

func NewJournalEntryRepository(pool *pgxpool.Pool) *JournalEntryRepository {
	return &JournalEntryRepository{pool: pool}
}

func (r *JournalEntryRepository) Create(ctx context.Context, entry *models.JournalEntry) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	query := `
			INSERT INTO journal_entries (content)
			VALUES ($1)
			RETURNING id, created_at, updated_at`

	err = tx.QueryRow(ctx, query, entry.Content).
		Scan(&entry.ID, &entry.CreatedAt, &entry.UpdatedAt)
	if err != nil {
		return err
	}

	for _, tag := range entry.ValueTags {
		if _, err := tx.Exec(ctx, `INSERT INTO journal_values (journal_entry_id, value_id, impact) VALUES ($1, $2, $3)`, entry.ID, tag.ValueID, tag.Impact); err != nil {
			if isForeignKeyViolation(err) {
				return ErrValueNotFound
			} else if isCheckViolation(err) {
				return ErrInvalidValue
			}
			return err
		}
	}

	return tx.Commit(ctx)
}

func (r *JournalEntryRepository) GetByID(ctx context.Context, id string) (*models.JournalEntry, error) {
	query := `
              SELECT id, content, created_at, updated_at
              FROM journal_entries
              WHERE id = $1`

	entry := &models.JournalEntry{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&entry.ID,
		&entry.Content,
		&entry.CreatedAt,
		&entry.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	valueTags, err := r.valueTagsForEntry(ctx, entry.ID)
	if err != nil {
		return nil, err
	}
	entry.ValueTags = valueTags

	return entry, nil
}

func (r *JournalEntryRepository) valueTagsForEntry(ctx context.Context, entryID string) ([]models.JournalValueTag, error) {
	rows, err := r.pool.Query(ctx, `SELECT value_id, impact FROM journal_values WHERE journal_entry_id = $1 ORDER BY value_id`, entryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	valueTags := []models.JournalValueTag{}
	for rows.Next() {
		var tag models.JournalValueTag
		if err := rows.Scan(&tag.ValueID, &tag.Impact); err != nil {
			return nil, err
		}
		valueTags = append(valueTags, tag)
	}

	return valueTags, rows.Err()
}

func (r *JournalEntryRepository) List(ctx context.Context) ([]*models.JournalEntry, error) {
	query := `
              SELECT id, content, created_at, updated_at
              FROM journal_entries
              ORDER BY created_at DESC`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	entries := []*models.JournalEntry{}
	for rows.Next() {
		entry := &models.JournalEntry{}

		err := rows.Scan(
			&entry.ID,
			&entry.Content,
			&entry.CreatedAt,
			&entry.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		entries = append(entries, entry)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := r.attachValueTags(ctx, entries); err != nil {
		return nil, err
	}

	return entries, nil
}

func (r *JournalEntryRepository) attachValueTags(ctx context.Context, entries []*models.JournalEntry) error {
	if len(entries) == 0 {
		return nil
	}

	ids := make([]string, len(entries))
	for i, entry := range entries {
		ids[i] = entry.ID
	}

	rows, err := r.pool.Query(ctx, `SELECT journal_entry_id, value_id, impact FROM journal_values WHERE journal_entry_id = ANY($1::uuid[]) ORDER BY value_id`, ids)
	if err != nil {
		return err
	}
	defer rows.Close()

	tagsByEntry := map[string][]models.JournalValueTag{}
	for rows.Next() {
		var entryID string
		var tag models.JournalValueTag
		if err := rows.Scan(&entryID, &tag.ValueID, &tag.Impact); err != nil {
			return err
		}
		tagsByEntry[entryID] = append(tagsByEntry[entryID], tag)
	}
	if err := rows.Err(); err != nil {
		return err
	}

	for _, entry := range entries {
		entry.ValueTags = tagsByEntry[entry.ID]
	}

	return nil
}

func (r *JournalEntryRepository) Update(ctx context.Context, entry *models.JournalEntry) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	query := `
              UPDATE journal_entries
              SET content = $2,
                      updated_at = NOW()
              WHERE id = $1
              RETURNING id, created_at, updated_at`

	err = tx.QueryRow(ctx, query, entry.ID, entry.Content).
		Scan(&entry.ID, &entry.CreatedAt, &entry.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		return err
	}

	if _, err := tx.Exec(ctx, `DELETE FROM journal_values WHERE journal_entry_id = $1`, entry.ID); err != nil {
		return err
	}

	for _, tag := range entry.ValueTags {
		if _, err := tx.Exec(ctx, `INSERT INTO journal_values (journal_entry_id, value_id, impact) VALUES ($1, $2, $3)`, entry.ID, tag.ValueID, tag.Impact); err != nil {
			if isForeignKeyViolation(err) {
				return ErrValueNotFound
			} else if isCheckViolation(err) {
				return ErrInvalidValue
			}
			return err
		}
	}

	return tx.Commit(ctx)
}

func (r *JournalEntryRepository) Delete(ctx context.Context, id string) error {
	commandTag, err := r.pool.Exec(ctx, `DELETE FROM journal_entries WHERE id = $1`, id)
	if err != nil {
		return err
	}

	if commandTag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}
