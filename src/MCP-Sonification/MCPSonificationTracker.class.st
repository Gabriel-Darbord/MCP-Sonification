"
I remember what tool calls did, so a call's sound can depend on its context. For each finished call I answer its phases, most important first; the bank plays the first one it maps:

	failed (error, failure, timeout):   repeated-failure (the streakLength-th failure in a row or more), timeout, very-slow, then failure or error
	succeeded:                          recovered (this tool failed last time), very-slow, slow, then success

Durations come from the observability record. I also track which calls are still running, so a waiting event can play for a call that takes longer than waitingDelay.

Defaults: waiting after 2 s, slow from 3 s, very slow from 30 s, a streak from 2 failures. Calls may come from several processes; a mutex guards my state.
"
Class {
	#name : 'MCPSonificationTracker',
	#superclass : 'Object',
	#instVars : [
		'mutex',
		'failureStreak',
		'lastOutcomes',
		'runningCalls',
		'waitingDelay',
		'slowDuration',
		'verySlowDuration',
		'streakLength'
	],
	#category : 'MCP-Sonification-MCP',
	#package : 'MCP-Sonification',
	#tag : 'MCP'
}

{ #category : 'tracking' }
MCPSonificationTracker >> callStarted: aRecord [

	mutex critical: [ runningCalls add: aRecord ]
]

{ #category : 'accessing' }
MCPSonificationTracker >> failureStreak [

	^ failureStreak
]

{ #category : 'initialization' }
MCPSonificationTracker >> initialize [

	super initialize.
	mutex := Mutex new.
	failureStreak := 0.
	lastOutcomes := Dictionary new.
	runningCalls := IdentitySet new.
	waitingDelay := 2 seconds.
	slowDuration := 3 seconds.
	verySlowDuration := 30 seconds.
	streakLength := 2
]

{ #category : 'private' }
MCPSonificationTracker >> isFailure: anOutcome [

	^ #( 'error' 'failure' 'timeout' ) includes: anOutcome
]

{ #category : 'tracking' }
MCPSonificationTracker >> isRunning: aRecord [

	^ mutex critical: [ runningCalls includes: aRecord ]
]

{ #category : 'private' }
MCPSonificationTracker >> phasesForFailure: anOutcome lasting: aDuration [

	^ Array streamContents: [ :stream |
			  failureStreak >= streakLength ifTrue: [ stream nextPut: 'repeated-failure' ].
			  anOutcome = 'timeout' ifTrue: [ stream nextPut: 'timeout' ].
			  aDuration >= verySlowDuration ifTrue: [ stream nextPut: 'very-slow' ].
			  stream nextPut: (anOutcome = 'timeout'
					   ifTrue: [ 'failure' ]
					   ifFalse: [ anOutcome ]) ]
]

{ #category : 'tracking' }
MCPSonificationTracker >> phasesForFinished: aRecord outcome: anOutcome [
	"Remember aRecord's outcome and answer its phases, most important first."

	^ mutex critical: [
			  | failedBefore duration |
			  runningCalls remove: aRecord ifAbsent: [ ].
			  failedBefore := self isFailure: (lastOutcomes at: aRecord toolName ifAbsent: [ 'success' ]).
			  lastOutcomes at: aRecord toolName put: anOutcome.
			  duration := (aRecord durationMilliseconds ifNil: [ 0 ]) milliSeconds.
			  (self isFailure: anOutcome)
				  ifTrue: [
						  failureStreak := failureStreak + 1.
						  self phasesForFailure: anOutcome lasting: duration ]
				  ifFalse: [
						  failureStreak := 0.
						  self phasesForSuccessLasting: duration afterFailure: failedBefore ] ]
]

{ #category : 'private' }
MCPSonificationTracker >> phasesForSuccessLasting: aDuration afterFailure: hadFailed [

	^ Array streamContents: [ :stream |
			  hadFailed ifTrue: [ stream nextPut: 'recovered' ].
			  aDuration >= verySlowDuration ifTrue: [ stream nextPut: 'very-slow' ].
			  aDuration >= slowDuration ifTrue: [ stream nextPut: 'slow' ].
			  stream nextPut: 'success' ]
]

{ #category : 'settings' }
MCPSonificationTracker >> slowDuration [

	^ slowDuration
]

{ #category : 'settings' }
MCPSonificationTracker >> slowDuration: aDuration [

	slowDuration := aDuration
]

{ #category : 'settings' }
MCPSonificationTracker >> streakLength [

	^ streakLength
]

{ #category : 'settings' }
MCPSonificationTracker >> streakLength: anInteger [

	streakLength := anInteger
]

{ #category : 'settings' }
MCPSonificationTracker >> verySlowDuration [

	^ verySlowDuration
]

{ #category : 'settings' }
MCPSonificationTracker >> verySlowDuration: aDuration [

	verySlowDuration := aDuration
]

{ #category : 'settings' }
MCPSonificationTracker >> waitingDelay [

	^ waitingDelay
]

{ #category : 'settings' }
MCPSonificationTracker >> waitingDelay: aDuration [

	waitingDelay := aDuration
]
