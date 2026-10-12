To modify the starting range of flying movement modify this variable:

Minimum is 200 maximum is your screen range (typically 1900)
RANGE := 900 * scaleX

Example:

Range := 600 * scaleX

To modify the setting of match logic or unlimited modify this values

low_20 := "match"
low_30 := "match"
low_60 := "match"

high_30 := "match"
high_60 := "unlimited"

Example

low_20 := "unlimited"
low_30 := "unlimited"
low_60 := "unlimited"

high_30 := "match"
high_60 := "match"