package repository

import "errors"

var ErrNotFound = errors.New("record not found")
var ErrValueRequired = errors.New("at least one value is required")
var ErrValueNotFound = errors.New("one or more values not found")
var ErrHabitRequired = errors.New("at least one habit is required")
var ErrHabitNotFound = errors.New("one or more habits not found")
var ErrInvalidValue = errors.New("invalid field value")
