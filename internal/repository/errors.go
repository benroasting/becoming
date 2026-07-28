package repository

import "errors"

var ErrNotFound = errors.New("record not found")
var ErrValueRequired = errors.New("at least one value is required")
var ErrValueNotFound = errors.New("one or more values not found")
