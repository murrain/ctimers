# CTimers
Custom timer addon for Windower

Commands:

    `//ct add NAME H M S`
    `//ct add NAME H:M:S`
    `//ct add NAME H:M:S hnm`
    `//ct del NAME`
    `//ct list`

Examples:

    //ctimers add Einherjar 1 0 0
	Creates a timer starting at 1 hour, 0 minutes, 0 seconds
    //ctimers add Einherjar 21:09:19
	Creates a timer at the specified clock time
    //ctimers add Fafnir 17:20:15 hnm
    Creates a timer at the specified time with repeating alarms every 10 minutes, 7 times.
    //ctimers del Einherjar
	Will set previous timer to 0 so that it is cleaned up
    //ctimers list
	List all currently active timers

