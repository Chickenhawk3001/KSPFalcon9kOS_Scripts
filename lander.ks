print "waiting for test message!".
set startLand to 0.
set thrott to 0.

WAIT UNTIL NOT CORE:MESSAGES:EMPTY. // make sure we've received something
SET RECEIVED TO CORE:MESSAGES:POP.
IF RECEIVED:CONTENT = "test" {
  PRINT "received! Sending one back!".
  
    SET MESSAGE TO "return". // can be any serializable value or a primitive
    SET P TO PROCESSOR("Command Module").
    IF P:CONNECTION:SENDMESSAGE(MESSAGE) {
       PRINT "Sent back!".
    }

} ELSE {
  PRINT "Unexpected message: " + RECEIVED:CONTENT.
}
CORE:MESSAGES:CLEAR().
print CORE:MESSAGES:LENGTH.


//wait for real message
clearscreen.

print "waiting for message!".
WAIT UNTIL NOT CORE:MESSAGES:EMPTY. // make sure we've received something
SET RECEIVED TO CORE:MESSAGES:POP.
IF RECEIVED:CONTENT = "go" {
  PRINT "Attempting to land".
  set startLand to 1.
} ELSE {
  PRINT "Unexpected message: " + RECEIVED:CONTENT.
}

wait until startLand > 0.

BRAKES ON.
lock steering to srfRetrograde.
wait 10.
lock steering to heading(270,0).
lock throttle to thrott.
set thrott to 1.
If ADDONS:TR:HASIMPACT = true {
  print "Impact exists.".
}
wait 5.1. // landing pad pos is ~74.55 W , ~0.97 S. Adjust the time for the payload weight. 7.33 Original
print "Impact is now close to launch pad.".
set thrott to 0.
local bounds_box is ship:bounds.
suicideBurn().

//landing stuff here

function suicideBurn {
    lock steering to srfRetrograde.
    lock pct to stoppingDistance() / distToGRD().
    toggle AG1.

    wait until pct >= 1.
    lock throttle to pct.
    until ship:verticalSpeed < 1 {}
    when distToGRD() <= 400 then { GEAR ON. }
    wait until ship:verticalSpeed >= 0.
    lock throttle to 0.
    unlock steering.
    SAS ON.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    toggle AG1.
    BRAKES OFF.
    wait 5.
    RCS OFF.
}

function stoppingDistance {
    local grav is 9.81. // Gravity
    local descentV is 0.001. // add or subtract velocity to make the touchdown softer or harder. Too extreme of values will cause a hover or a crater.
    local maxDeceleration is ((ship:availableThrust / ship:mass) - (grav)) - descentV. // how fast can we slow down
    return ship:verticalSpeed^2 / (2 * maxDeceleration).
}

function distToGRD {
    return round(bounds_box:BOTTOMALTRADAR, 1).
}