// basic project to help me learn kOS
// made by: Chickenhawk3001

set targetA to 125000.
set targetP to 125000.
set PreDir to (90).

set flagA to false.
set flagB to false.

clearscreen.

// screen variables
lock traj to "OFFLINE".
lock comms to "OFFLINE".
lock TVal to 0.8.
lock TAngle to 90.
lock phase to "PRE-CHECKS".

lock words to "".
lock numbers to "".

if ADDONS:TR:AVAILABLE {
    lock traj to "ONLINE".
} else {
    lock traj to "FAILED".
}

if flagB = false {
    set MESSAGE TO "test". // can be any serializable value or a primitive
    set P TO PROCESSOR("Booster").
    IF P:CONNECTION:SENDMESSAGE(MESSAGE) {}

    WAIT UNTIL NOT CORE:MESSAGES:EMPTY. // make sure we've received something
    set RECEIVED TO CORE:MESSAGES:POP.
    IF RECEIVED:CONTENT = "return" {
        lock comms to "ONLINE".
    } ELSE {
        lock comms to "FAILED".
    }

    set flagB to true.
}

lock phase to "START-UP".
lock throttle to TVal.
lock steering to UP.
SAS OFF.
lock words to "Countdown: ".

set runMode to 1.

until runMode = 0 {

    if runMode = 1 { // Launch
        FROM {SET X to 10.} UNTIL X <= 0 STEP {SET X to X - 1.} DO {
            update().
            lock numbers to X.
            wait 1.
        }

        lock phase to "LAUNCH".
        set words to " ".
        set numbers to "  ".

        stage.
        GEAR OFF.
        lock steering to heading(PreDir,TAngle).
        set runMode to 8.
    }

    if runMode = 2 { // 10000 >= ALT:RADAR >= 5000 
        if ALT:RADAR >= 10000 {
            lock TAngle to 45.
            set runMode to 3.
        }
    }

    if runMode = 3 { // 20000 >= ALT:RADAR >= 10000 
        if ALT:RADAR >= 20000 {
            lock TAngle to 40.
            set runMode to 5.
        }
    }

    if runMode = 5 { // FINAL BURN
        if SHIP:APOAPSIS >= targetA {
            lock phase to "Coasting".
            lock TVal to 0.
            lock TAngle to 0.
            RCS ON.
            if ETA:APOAPSIS <= 5 {
                set runMode to 6.
            }
        } else {
            lock TAngle to 40.
        }
    }

    if runMode = 6 {
        lock TVal to 1.
        lock phase to "Circularizing".
        set runMode to 7.
    }

    if runMode = 7  {
        if Periapsis >= targetP {
            lock TVal to 0.
            lock TAngle to 0.
            lock throttle to 0.
            set SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
            RCS OFF.
            unlock steering.
            SAS ON.
            lock phase to "Shutting Down".
            set runMode to 0. // Shutdown
            wait 5.
        } else {

            if ETA:APOAPSIS <= 2 OR ETA:APOAPSIS >= 600 {
                lock TAngle to 12.5.
            } else {
                lock TAngle to 0.
            }

        }
    }

    if runMode = 8 {
        if ALT:RADAR >= 5000 {
            lock TAngle to 65.
            set runMode to 2.
        }
    }

    if flagA = false AND STAGE:LIQUIDFUEL <= 1200 AND STAGE:LIQUIDFUEL > 0 { // Stage with ~1400m/s of deltaV for the booster
        lock phase to "LAUNCH - 2nd Stage Deployed".
        lock TVal to 0.
        wait 1. 
        RCS ON.
        set MESSAGE TO "go". // send the message right before seperation for ease.
        IF P:CONNECTION:SENDMESSAGE(MESSAGE) {
            set words to "Success!".
        } else {
            set words to "Failed.".
        }
        STAGE.
        RCS OFF.
        wait 3.
        lock TVal to 1.
        set flagA to true.
        
        set P to "Command Module".
        set MESSAGE to " ".
        set words to " ".
    }

    update().

    function update {
        print "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ " + "                    " at (0,0). //
        print "SYSTEMS: " + "                                                   " at (0,1). // Systems:
        print "   Trajectories: " + traj + "                                    " at (0,2). // Check
        print "   Communication: " + comms + "                                  " at (0,3). // Check
        print "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ " + "                    " at (0,4). //
        print "SHIP: " + "                                                      " at (0,5). // SHIP:
        print "   Phase: " + phase + "                                          " at (0,6). // Phase
        print "   Throttle: " + (TVal * 100) + "                                " at (0,7). // Throttle %
        print "   Angle: " + TAngle + "                                         " at (0,8). // Angle
        print "   Apoapsis: " + round(SHIP:APOAPSIS) + " meters" + "            " at (0,9). // Apoapsis
        print "   Periapsis: " + round(SHIP:PERIAPSIS) + " meters" + "          " at (0,10).// Periapsis
        print "                                                                 " at (0,11).// 
        print "   " + words + numbers + "                                       " at (0,12).// Random counter, many uses
        print "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ " + "                    " at (0,13).//
    }
    
    wait 0.001. // The infinite power of wait for less than a physics tick keeps the program from running some stuff more than others when lag occurs.
}