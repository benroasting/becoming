package repository

import (
	"context"
	"errors"

	"github.com/benroasting/becoming/internal/models"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type GoalFilter struct {
	Status *string
}

type GoalRepository struct {
	pool *pgxpool.Pool
}

func NewGoalRepository(pool *pgxpool.Pool) *GoalRepository {
	return &GoalRepository{pool: pool}
}

func (r *GoalRepository) Create(ctx context.Context, goal *models.Goal) error {
	if len(goal.ValueIDs) == 0 {
		return ErrValueRequired
	}
	if len(goal.HabitIDs) == 0 {
		return ErrHabitRequired
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	query := `
              INSERT INTO goals (title, description)
              VALUES ($1, $2)
              RETURNING id, status, created_at, updated_at`

	err = tx.QueryRow(ctx, query, goal.Title, goal.Description).
		Scan(&goal.ID, &goal.Status, &goal.CreatedAt, &goal.UpdatedAt)

	if err != nil {
		return err
	}

	for _, valueID := range goal.ValueIDs {
		if _, err := tx.Exec(ctx, `INSERT INTO goal_values (goal_id, value_id) VALUES ($1, $2)`, goal.ID, valueID); err != nil {
			if isForeignKeyViolation(err) {
				return ErrValueNotFound
			}
			return err
		}
	}

	for _, habitID := range goal.HabitIDs {
		if _, err := tx.Exec(ctx, `INSERT INTO habit_goals (habit_id, goal_id) VALUES ($1, $2)`, habitID, goal.ID); err != nil {
			if isForeignKeyViolation(err) {
				return ErrHabitNotFound
			}
			return err
		}
	}

	return tx.Commit(ctx)
}

func (r *GoalRepository) GetByID(ctx context.Context, id string) (*models.Goal, error) {
	query := `
              SELECT id, title, description, status, created_at, updated_at
              FROM goals
              WHERE id = $1`

	goal := &models.Goal{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&goal.ID,
		&goal.Title,
		&goal.Description,
		&goal.Status,
		&goal.CreatedAt,
		&goal.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	valueIDs, err := r.valueIDsForGoal(ctx, goal.ID)
	if err != nil {
		return nil, err
	}
	goal.ValueIDs = valueIDs

	habitIDs, err := r.habitIDsForGoal(ctx, goal.ID)
	if err != nil {
		return nil, err
	}
	goal.HabitIDs = habitIDs

	return goal, nil
}

func (r *GoalRepository) valueIDsForGoal(ctx context.Context, goalID string) ([]string, error) {
	rows, err := r.pool.Query(ctx, `SELECT value_id FROM goal_values WHERE goal_id = $1 ORDER BY value_id`, goalID)
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

func (r *GoalRepository) habitIDsForGoal(ctx context.Context, goalID string) ([]string, error) {
	rows, err := r.pool.Query(ctx, `SELECT habit_id FROM habit_goals WHERE goal_id = $1 ORDER BY habit_id`, goalID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	habitIDs := []string{}
	for rows.Next() {
		var habitID string
		if err := rows.Scan(&habitID); err != nil {
			return nil, err
		}
		habitIDs = append(habitIDs, habitID)
	}

	return habitIDs, rows.Err()
}

func (r *GoalRepository) List(ctx context.Context, filter GoalFilter) ([]*models.Goal, error) {
	query := `
              SELECT id, title, description, status, created_at, updated_at
              FROM goals
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

	goals := []*models.Goal{}
	for rows.Next() {
		goal := &models.Goal{}

		err := rows.Scan(
			&goal.ID,
			&goal.Title,
			&goal.Description,
			&goal.Status,
			&goal.CreatedAt,
			&goal.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		goals = append(goals, goal)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := r.attachAssociations(ctx, goals); err != nil {
		return nil, err
	}

	return goals, nil
}

func (r *GoalRepository) attachAssociations(ctx context.Context, goals []*models.Goal) error {
	if len(goals) == 0 {
		return nil
	}

	ids := make([]string, len(goals))
	for i, goal := range goals {
		ids[i] = goal.ID
	}

	valueRows, err := r.pool.Query(ctx, `SELECT goal_id, value_id FROM goal_values WHERE goal_id = ANY($1::uuid[]) ORDER BY value_id`, ids)
	if err != nil {
		return err
	}
	defer valueRows.Close()

	valueIDsByGoal := map[string][]string{}
	for valueRows.Next() {
		var goalID, valueID string
		if err := valueRows.Scan(&goalID, &valueID); err != nil {
			return err
		}
		valueIDsByGoal[goalID] = append(valueIDsByGoal[goalID], valueID)
	}
	if err := valueRows.Err(); err != nil {
		return err
	}

	habitRows, err := r.pool.Query(ctx, `SELECT goal_id, habit_id FROM habit_goals WHERE goal_id = ANY($1::uuid[]) ORDER BY habit_id`, ids)
	if err != nil {
		return err
	}
	defer habitRows.Close()

	habitIDsByGoal := map[string][]string{}
	for habitRows.Next() {
		var goalID, habitID string
		if err := habitRows.Scan(&goalID, &habitID); err != nil {
			return err
		}
		habitIDsByGoal[goalID] = append(habitIDsByGoal[goalID], habitID)
	}
	if err := habitRows.Err(); err != nil {
		return err
	}

	for _, goal := range goals {
		goal.ValueIDs = valueIDsByGoal[goal.ID]
		goal.HabitIDs = habitIDsByGoal[goal.ID]
	}

	return nil
}

func (r *GoalRepository) Update(ctx context.Context, goal *models.Goal) error {
	if len(goal.ValueIDs) == 0 {
		return ErrValueRequired
	}
	if len(goal.HabitIDs) == 0 {
		return ErrHabitRequired
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	query := `
              UPDATE goals
              SET title = $2,
                      description = $3,
                      status = $4,
                      updated_at = NOW()
              WHERE id = $1
              RETURNING id, created_at, updated_at`

	err = tx.QueryRow(ctx, query, goal.ID, goal.Title, goal.Description, goal.Status).
		Scan(&goal.ID, &goal.CreatedAt, &goal.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		if isCheckViolation(err) {
			return ErrInvalidValue
		}
		return err
	}

	if _, err := tx.Exec(ctx, `DELETE FROM goal_values WHERE goal_id = $1`, goal.ID); err != nil {
		return err
	}

	for _, valueID := range goal.ValueIDs {
		if _, err := tx.Exec(ctx, `INSERT INTO goal_values (goal_id, value_id) VALUES ($1, $2)`, goal.ID, valueID); err != nil {
			if isForeignKeyViolation(err) {
				return ErrValueNotFound
			}
			return err
		}
	}

	if _, err := tx.Exec(ctx, `DELETE FROM habit_goals WHERE goal_id = $1`, goal.ID); err != nil {
		return err
	}

	for _, habitID := range goal.HabitIDs {
		if _, err := tx.Exec(ctx, `INSERT INTO habit_goals (habit_id, goal_id) VALUES ($1, $2)`, habitID, goal.ID); err != nil {
			if isForeignKeyViolation(err) {
				return ErrHabitNotFound
			}
			return err
		}
	}

	return tx.Commit(ctx)
}
