"
I test the phases the tracker answers from outcomes and durations, with finished observability records.
"
Class {
	#name : 'MCPSonificationTrackerTest',
	#superclass : 'TestCase',
	#instVars : [
		'tracker'
	],
	#category : 'MCP-Sonification-Tests',
	#package : 'MCP-Sonification-Tests'
}

{ #category : 'helpers' }
MCPSonificationTrackerTest >> finish: aToolName after: milliseconds with: anOutcome [

	| record |
	record := MCPToolCallRecord new.
	record
		toolName: aToolName;
		finishAt: DateAndTime now durationMilliseconds: milliseconds status: 'ok'.
	tracker callStarted: record.
	^ tracker phasesForFinished: record outcome: anOutcome
]

{ #category : 'running' }
MCPSonificationTrackerTest >> setUp [

	super setUp.
	tracker := MCPSonificationTracker new
]

{ #category : 'tests' }
MCPSonificationTrackerTest >> testFinishedCallsAreNoLongerRunning [

	| record |
	record := MCPToolCallRecord new.
	record toolName: 'x'.
	tracker callStarted: record.
	self assert: (tracker isRunning: record).
	tracker phasesForFinished: record outcome: 'success'.
	self deny: (tracker isRunning: record)
]

{ #category : 'tests' }
MCPSonificationTrackerTest >> testQuickSuccess [

	self assert: (self finish: 'class_get' after: 10 with: 'success') equals: #( 'success' )
]

{ #category : 'tests' }
MCPSonificationTrackerTest >> testRecoveredOnlyAfterTheSameToolFailed [

	self finish: 'test_run' after: 1 with: 'timeout'.
	self assert: (self finish: 'class_get' after: 1 with: 'success') equals: #( 'success' ).
	self assert: (self finish: 'test_run' after: 1 with: 'success') equals: #( 'recovered' 'success' ).
	self assert: (self finish: 'test_run' after: 1 with: 'success') equals: #( 'success' )
]

{ #category : 'tests' }
MCPSonificationTrackerTest >> testSlowAndVerySlowSuccesses [

	self assert: (self finish: 'image_evaluate' after: 4000 with: 'success') equals: #( 'slow' 'success' ).
	self assert: (self finish: 'image_evaluate' after: 45000 with: 'success') equals: #( 'very-slow' 'slow' 'success' )
]

{ #category : 'tests' }
MCPSonificationTrackerTest >> testStreakLengthIsASetting [

	tracker streakLength: 3.
	self finish: 'a' after: 1 with: 'error'.
	self assert: (self finish: 'a' after: 1 with: 'error') equals: #( 'error' ).
	self assert: (self finish: 'a' after: 1 with: 'error') equals: #( 'repeated-failure' 'error' )
]

{ #category : 'tests' }
MCPSonificationTrackerTest >> testStreakSpansToolsAndResetsOnSuccess [

	self finish: 'a' after: 1 with: 'error'.
	self assert: (self finish: 'b' after: 1 with: 'failure') equals: #( 'repeated-failure' 'failure' ).
	self assert: tracker failureStreak equals: 2.
	self finish: 'c' after: 1 with: 'success'.
	self assert: tracker failureStreak equals: 0.
	self assert: (self finish: 'a' after: 1 with: 'error') equals: #( 'error' )
]

{ #category : 'tests' }
MCPSonificationTrackerTest >> testVerySlowFailure [

	self assert: (self finish: 'test_run' after: 45000 with: 'failure') equals: #( 'very-slow' 'failure' )
]
