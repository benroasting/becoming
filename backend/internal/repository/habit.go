package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/benroasting/becoming/internal/models"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

type HabitFilter struct {
	IsActive  *bool
	Frequency *string
}

type HabitRepository struct {
	pool *pgxpool.Pool
}

func NewHabitRepository(pool *pgxpool.Pool) *HabitRepository {
	return &HabitRepository{pool: pool}
}

func isForeignKeyViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23503"
}

func isCheckViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23514"
}

func (r *HabitRepository) Create(ctx context.Context, habit *models.Habit) error {
	if len(habit.ValueIDs) == 0 {
		return ErrValueRequired
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var reminderHour, reminderMinute *int
	if habit.ReminderTime != nil {
		reminderHour = &habit.ReminderTime.Hour
		reminderMinute = &habit.ReminderTime.Minute
	}

	query := `
              INSERT INTO habits (title, description, frequency, custom_days, reminder_hour, reminder_minute)
              VALUES ($1, $2, $3, $4, $5, $6)
              RETURNING id, is_active, created_at, updated_at`

	err = tx.QueryRow(ctx, query,
		habit.Title,
		habit.Description,
		habit.Frequency,
		habit.CustomDays,
		reminderHour,
		reminderMinute,
	).Scan(&habit.ID, &habit.IsActive, &habit.CreatedAt, &habit.UpdatedAt)
	if err != nil {
		if isCheckViolation(err) {
			return ErrInvalidValue
		}
		return err
	}

	for _, valueID := range habit.ValueIDs {
		if _, err := tx.Exec(ctx, `INSERT INTO habit_values (habit_id, value_id) VALUES ($1, $2)`, habit.ID, valueID); err != nil {
			if isForeignKeyViolation(err) {
				return ErrValueNotFound
			}
			return err
		}
	}

	return tx.Commit(ctx)
}

func (r *HabitRepository) GetByID(ctx context.Context, id string) (*models.Habit, error) {
	query := `
              SELECT id, title, description, frequency, custom_days, reminder_hour, reminder_minute, is_active, created_at, updated_at
              FROM habits
              WHERE id = $1`

	habit := &models.Habit{}
	var reminderHour, reminderMinute *int
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&habit.ID,
		&habit.Title,
		&habit.Description,
		&habit.Frequency,
		&habit.CustomDays,
		&reminderHour,
		&reminderMinute,
		&habit.IsActive,
		&habit.CreatedAt,
		&habit.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	if reminderHour != nil && reminderMinute != nil {
		habit.ReminderTime = &models.TimeOfDay{Hour: *reminderHour, Minute: *reminderMinute}
	}

	valueIDs, err := r.valueIDsForHabit(ctx, habit.ID)
	if err != nil {
		return nil, err
	}
	habit.ValueIDs = valueIDs

	return habit, nil
}

func (r *HabitRepository) valueIDsForHabit(ctx context.Context, habitID string) ([]string, error) {
	rows, err := r.pool.Query(ctx, `SELECT value_id FROM habit_values WHERE habit_id = $1 ORDER BY value_id`, habitID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	valueIDs := []string{}
	for rows.Next() {
		var valueID string
		if err := rows.Scan(&valueID); err != nil {
			return nil, err
		}
		valueIDs = append(valueIDs, valueID)
	}

	return valueIDs, rows.Err()
}

func (r *HabitRepository) List(ctx context.Context, filter HabitFilter) ([]*models.Habit, error) {
	query := `
              SELECT id, title, description, frequency, custom_days, 
			  reminder_hour, reminder_minute, is_active, created_at, updated_at
              FROM habits
              WHERE 1=1`

	args := []any{}
	argPos := 1

	if filter.IsActive != nil {
		query += fmt.Sprintf(" AND is_active =$%d", argPos)
		args = append(args, *filter.IsActive)
		argPos++
	}

	if filter.Frequency != nil {
		query += fmt.Sprintf(" AND frequency =$%d", argPos)
		args = append(args, *filter.Frequency)
		argPos++
	}

	query += " ORDER by created_at DESC"

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	habits := []*models.Habit{}
	for rows.Next() {
		habit := &models.Habit{}

		var reminderHour, reminderMinute *int

		err := rows.Scan(
			&habit.ID,
			&habit.Title,
			&habit.Description,
			&habit.Frequency,
			&habit.CustomDays,
			&reminderHour,
			&reminderMinute,
			&habit.IsActive,
			&habit.CreatedAt,
			&habit.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		if reminderHour != nil && reminderMinute != nil {
			habit.ReminderTime = &models.TimeOfDay{Hour: *reminderHour, Minute: *reminderMinute}
		}

		habits = append(habits, habit)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	if err = r.attachValueIDs(ctx, habits); err != nil {
		return nil, err
	}

	return habits, nil

}

func (r *HabitRepository) attachValueIDs(ctx context.Context, habits []*models.Habit) error {
	if len(habits) == 0 {
		return nil
	}

	ids := make([]string, len(habits))
	for i, habit := range habits {
		ids[i] = habit.ID
	}

	rows, err := r.pool.Query(ctx, `SELECT habit_id, value_id FROM habit_values WHERE habit_id = ANY($1::uuid[]) ORDER BY value_id`, ids)
	if err != nil {
		return err
	}
	defer rows.Close()

	valueIDsByHabit := map[string][]string{}
	for rows.Next() {
		var habitID, valueID string
		if err := rows.Scan(&habitID, &valueID); err != nil {
			return err
		}
		valueIDsByHabit[habitID] = append(valueIDsByHabit[habitID], valueID)
	}
	if err := rows.Err(); err != nil {
		return err
	}

	for _, habit := range habits {
		habit.ValueIDs = valueIDsByHabit[habit.ID]
	}

	return nil
}

func (r *HabitRepository) Update(ctx context.Context, habit *models.Habit) error {
	if len(habit.ValueIDs) == 0 {
		return ErrValueRequired
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var reminderHour, reminderMinute *int
	if habit.ReminderTime != nil {
		reminderHour = &habit.ReminderTime.Hour
		reminderMinute = &habit.ReminderTime.Minute
	}

	query := `
              UPDATE habits
              SET title = $2,
                      description = $3,
                      frequency = $4,
                      custom_days = $5,
                      reminder_hour = $6,
                      reminder_minute = $7,
                      updated_at = NOW()
              WHERE id = $1
              RETURNING id, is_active, created_at, updated_at`

	err = tx.QueryRow(ctx, query,
		habit.ID,
		habit.Title,
		habit.Description,
		habit.Frequency,
		habit.CustomDays,
		reminderHour,
		reminderMinute,
	).Scan(&habit.ID, &habit.IsActive, &habit.CreatedAt, &habit.UpdatedAt)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		if isCheckViolation(err) {
			return ErrInvalidValue
		}
		return err
	}

	if _, err := tx.Exec(ctx, `DELETE FROM habit_values WHERE habit_id = $1`, habit.ID); err != nil {
		return err
	}

	for _, valueID := range habit.ValueIDs {
		if _, err := tx.Exec(ctx, `INSERT INTO habit_values (habit_id, value_id) VALUES ($1, $2)`, habit.ID, valueID); err != nil {
			if isForeignKeyViolation(err) {
				return ErrValueNotFound
			}
			return err
		}
	}

	return tx.Commit(ctx)
}

func (r *HabitRepository) Archive(ctx context.Context, id string) error {
	query := `
              UPDATE habits
              SET is_active = false, updated_at = NOW()
              WHERE id = $1 AND is_active = true`

	commandTag, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return err
	}

	if commandTag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}
