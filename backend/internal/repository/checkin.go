package repository

import (
	"context"

	"github.com/benroasting/becoming/internal/models"
	"github.com/jackc/pgx/v5/pgxpool"
)

type CheckInRepository struct {
	pool *pgxpool.Pool
}

func NewCheckInRepository(pool *pgxpool.Pool) *CheckInRepository {
	return &CheckInRepository{pool: pool}
}

func (r *CheckInRepository) Create(ctx context.Context, checkIn *models.CheckIn) error {
	query := `
              INSERT INTO check_ins (habit_id, completed_at, notes)
              VALUES ($1, $2, $3)
              RETURNING id, created_at`

	err := r.pool.QueryRow(ctx, query, checkIn.HabitID, checkIn.CompletedAt, checkIn.Notes).
		Scan(&checkIn.ID, &checkIn.CreatedAt)
	if err != nil {
		if isForeignKeyViolation(err) {
			return ErrNotFound
		}
		return err
	}

	return nil
}

func (r *CheckInRepository) ListByHabit(ctx context.Context, habitID string) ([]*models.CheckIn, error) {
	query := `
              SELECT id, habit_id, completed_at, notes, created_at
              FROM check_ins
              WHERE habit_id = $1
              ORDER BY completed_at DESC`

	rows, err := r.pool.Query(ctx, query, habitID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	checkIns := []*models.CheckIn{}
	for rows.Next() {
		checkIn := &models.CheckIn{}

		err := rows.Scan(
			&checkIn.ID,
			&checkIn.HabitID,
			&checkIn.CompletedAt,
			&checkIn.Notes,
			&checkIn.CreatedAt,
		)
		if err != nil {
			return nil, err
		}

		checkIns = append(checkIns, checkIn)
	}

	return checkIns, rows.Err()
}
