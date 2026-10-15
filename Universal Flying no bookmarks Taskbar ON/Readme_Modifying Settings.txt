To modify the settings open flying_script.json with a notepad

Example modification:

  "logic": {
    "high_30": "match",
    "high_60": "unlimited",
    "low_20": "match",
    "low_30": "match",
    "low_60": "match"
  },

to

  "logic": {
    "high_30": "unlimited",
    "high_60": "unlimited",
    "low_20": "unlimited",
    "low_30": "unlimited",
    "low_60": "unlimited"
  },