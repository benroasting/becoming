package repository

import (
	"context"
	"errors"

	"github.com/benroasting/becoming/internal/models"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ValueFilter struct {
	Status *string
}

type ValueRepository struct {
	pool *pgxpool.Pool
}

func NewValueRepository(pool *pgxpool.Pool) *ValueRepository {
	return &ValueRepository{
		pool: pool,
	}
}

func (r *ValueRepository) Create(ctx context.Context, value *models.Value) error {
	query := `
                              INSERT INTO core_values (title, description, status)
                              VALUES ($1, $2, 'active')
                              RETURNING id, created_at, updated_at`

	value.Status = models.ValueStatusActive

	return r.pool.QueryRow(ctx, query,
		value.Title,
		value.Description,
	).Scan(&value.ID, &value.CreatedAt, &value.UpdatedAt)
}

func (r *ValueRepository) GetByID(ctx context.Context, id string) (*models.Value, error) {
	query := `
				SELECT id, title, description, status, created_at, updated_at
				FROM core_values
				WHERE id = $1`

	value := &models.Value{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&value.ID,
		&value.Title,
		&value.Description,
		&value.Status,
		&value.CreatedAt,
		&value.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	return value, nil
}

func (r *ValueRepository) List(ctx context.Context, filter ValueFilter) ([]*models.Value, error) {
	query := `
				SELECT id, title, description, status, created_at, updated_at
				FROM core_values
				WHERE 1=1`

	args := []any{}
	if filter.Status != nil {
		query += ` AND status = $1`
		args = append(args, *filter.Status)
	}
	query += " ORDER BY created_at DESC"

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	values := []*models.Value{}
	for rows.Next() {
		value := &models.Value{}

		err := rows.Scan(
			&value.ID,
			&value.Title,
			&value.Description,
			&value.Status,
			&value.CreatedAt,
			&value.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		values = append(values, value)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return values, nil
}

func (r *ValueRepository) Update(ctx context.Context, value *models.Value) error {
	query := `
				UPDATE core_values
				SET title = $2,
						description = $3,
						updated_at = NOW()
				WHERE id = $1
				RETURNING id, title, description, status, created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		value.ID,
		value.Title,
		value.Description,
	).Scan(
		&value.ID,
		&value.Title,
		&value.Description,
		&value.Status,
		&value.CreatedAt,
		&value.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		return err
	}
	return nil
}

func (r *ValueRepository) Abandon(ctx context.Context, id string) error {
	query := `
				UPDATE core_values
				SET status = 'abandoned', updated_at = NOW()
				WHERE id = $1 AND status = 'active'`

	commandTag, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return err
	}

	if commandTag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil

}
