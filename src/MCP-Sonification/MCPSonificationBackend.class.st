"
I decorate an MCP observability backend: I forward everything to it, so its logs, metrics, and traces stay intact, and I also post SoundBank events (SBEvent) to an engine (SBEngine):
	- start, when a tool call starts;
	- waiting, when it is still running after a while;
	- when it finishes, its phases in context, most important first (see MCPSonificationTracker): repeated-failure, timeout, very-slow, failure, error, recovered, slow, success.

Event subjects go from the tool name to its group, read or write, then '*'; bank sets can add names in between. Calls through tool_call are reported once, by the tool they run.

Install me with `MCPSonificationBackend attachEngine: anEngine to: anMCP` and remove me with `detachFrom:`. `MCP>>observabilityEnabled: false` replaces me with a no-op backend. Tune the context with `anMCP observability tracker`.

A failure in sound handling is reported to the engine and never breaks the tool call. I sit in the path of every tool call: detach me before reshaping my class (renaming or removing slots), or the MCP server breaks.
"
Class {
	#name : 'MCPSonificationBackend',
	#superclass : 'MCPObservabilityBackend',
	#instVars : [
		'backend',
		'engine',
		'toolRegistry',
		'tracker'
	],
	#category : 'MCP-Sonification-MCP',
	#package : 'MCP-Sonification',
	#tag : 'MCP'
}

{ #category : 'attaching' }
MCPSonificationBackend class >> attachEngine: anEngine to: anMCP [
	"Decorate anMCP's local observability backend so its tool calls post events to anEngine. Attaching again replaces the previous decoration."

	anMCP observability:
		(self on: anMCP ensureLocalObservabilityBackend withoutSonification engine: anEngine toolRegistry: anMCP toolRegistry)
]

{ #category : 'attaching' }
MCPSonificationBackend class >> detachFrom: anMCP [

	anMCP observability: anMCP observability withoutSonification
]

{ #category : 'instance creation' }
MCPSonificationBackend class >> on: anObservabilityBackend engine: anEngine toolRegistry: aToolRegistry [

	^ self new
		  setBackend: anObservabilityBackend engine: anEngine toolRegistry: aToolRegistry;
		  yourself
]

{ #category : 'private - sounds' }
MCPSonificationBackend >> announceFinishOf: aRecord result: aToolResult error: anError [

	| outcome |
	(self isWrapper: aRecord toolName) ifTrue: [ ^ self ].
	outcome := anError ifNil: [ aToolResult sonificationPhase ] ifNotNil: [ 'error' ].
	self postToolNamed: aRecord toolName phases: (tracker phasesForFinished: aRecord outcome: outcome)
]

{ #category : 'private - sounds' }
MCPSonificationBackend >> announceStartOf: aToolName record: aRecord [

	(self isWrapper: aToolName) ifTrue: [ ^ self ].
	self postToolNamed: aToolName phases: #( 'start' ).
	aRecord ifNotNil: [
			tracker callStarted: aRecord.
			self announceWaitingFor: aRecord ]
]

{ #category : 'private - sounds' }
MCPSonificationBackend >> announceWaitingFor: aRecord [
	"Post a waiting event if the call is still running after the tracker's waiting delay. Above user priority, so it fires while the image is busy with that call."

	[
		tracker waitingDelay wait.
		(tracker isRunning: aRecord) ifTrue: [ self sonify: [ self postToolNamed: aRecord toolName phases: #( 'waiting' ) ] ] ]
		forkAt: Processor userInterruptPriority
		named: 'Sonification waiting timer'
]

{ #category : 'accessing' }
MCPSonificationBackend >> backend [

	^ backend
]

{ #category : 'clearing' }
MCPSonificationBackend >> clear [

	backend clear
]

{ #category : 'activation' }
MCPSonificationBackend >> disable [

	backend disable
]

{ #category : 'activation' }
MCPSonificationBackend >> enable [

	backend enable
]

{ #category : 'accessing' }
MCPSonificationBackend >> enabled [

	^ backend enabled
]

{ #category : 'accessing' }
MCPSonificationBackend >> enabled: aBoolean [

	backend enabled: aBoolean
]

{ #category : 'accessing' }
MCPSonificationBackend >> engine [

	^ engine
]

{ #category : 'private - sounds' }
MCPSonificationBackend >> eventForToolNamed: aToolName phases: somePhases [

	^ SBEvent
		  tool: (toolRegistry toolNamed: aToolName ifAbsent: [ ^ SBEvent unknownToolNamed: aToolName phases: somePhases ])
		  phases: somePhases
]

{ #category : 'accessing' }
MCPSonificationBackend >> exportDirectory [

	^ backend exportDirectory
]

{ #category : 'accessing' }
MCPSonificationBackend >> exportDirectory: aDirectory [

	backend exportDirectory: aDirectory
]

{ #category : 'testing' }
MCPSonificationBackend >> exportEnabled [

	^ backend exportEnabled
]

{ #category : 'accessing' }
MCPSonificationBackend >> exportInstanceDirectory [

	^ backend exportInstanceDirectory
]

{ #category : 'actions' }
MCPSonificationBackend >> forceFlush [

	backend forceFlush
]

{ #category : 'testing' }
MCPSonificationBackend >> isNoop [

	^ backend isNoop
]

{ #category : 'private - sounds' }
MCPSonificationBackend >> isWrapper: aToolName [
	"tool_call runs another tool, which reports its own start and finish."

	^ aToolName = 'tool_call'
]

{ #category : 'logging' }
MCPSonificationBackend >> logs [

	^ backend logs
]

{ #category : 'accessing' }
MCPSonificationBackend >> metrics [

	^ backend metrics
]

{ #category : 'private - sounds' }
MCPSonificationBackend >> postToolNamed: aToolName phases: somePhases [

	engine post: (self eventForToolNamed: aToolName phases: somePhases)
]

{ #category : 'accessing' }
MCPSonificationBackend >> recentCallRecords [

	^ backend recentCallRecords
]

{ #category : 'recording' }
MCPSonificationBackend >> recordSessionEndFor: anMCP [

	backend recordSessionEndFor: anMCP
]

{ #category : 'recording' }
MCPSonificationBackend >> recordSessionStartFor: anMCP [

	backend recordSessionStartFor: anMCP
]

{ #category : 'recording' }
MCPSonificationBackend >> recordToolCallFinish: aRecord result: aToolResult error: anError [
	"aRecord is nil when the wrapped backend records nothing, so there is no tool name to report."

	backend recordToolCallFinish: aRecord result: aToolResult error: anError.
	aRecord ifNotNil: [ self sonify: [ self announceFinishOf: aRecord result: aToolResult error: anError ] ]
]

{ #category : 'recording' }
MCPSonificationBackend >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [

	| record |
	record := backend
		          recordToolCallStart: aToolName
		          input: inputObject
		          dispatchPath: dispatchPath
		          context: contextDictionary.
	self sonify: [ self announceStartOf: aToolName record: record ].
	^ record
]

{ #category : 'accessing' }
MCPSonificationBackend >> resourceMetadata [

	^ backend resourceMetadata
]

{ #category : 'accessing' }
MCPSonificationBackend >> resourceMetadata: aDictionary [

	backend resourceMetadata: aDictionary
]

{ #category : 'initialization' }
MCPSonificationBackend >> setBackend: anObservabilityBackend engine: anEngine toolRegistry: aToolRegistry [

	backend := anObservabilityBackend.
	engine := anEngine.
	toolRegistry := aToolRegistry.
	tracker := MCPSonificationTracker new
]

{ #category : 'actions' }
MCPSonificationBackend >> shutdown [

	backend shutdown
]

{ #category : 'private - sounds' }
MCPSonificationBackend >> sonify: aBlock [
	"Sound must never break a tool call."

	aBlock
		on: Error
		do: [ :error | engine reportError: error ]
]

{ #category : 'displaying' }
MCPSonificationBackend >> statusText [

	^ backend statusText
]

{ #category : 'accessing' }
MCPSonificationBackend >> totalCallCount [

	^ backend totalCallCount
]

{ #category : 'accessing' }
MCPSonificationBackend >> totalErrorCount [

	^ backend totalErrorCount
]

{ #category : 'accessing' }
MCPSonificationBackend >> totalOutputBudgetExceededCount [

	^ backend totalOutputBudgetExceededCount
]

{ #category : 'accessing' }
MCPSonificationBackend >> traceRecords [

	^ backend traceRecords
]

{ #category : 'accessing' }
MCPSonificationBackend >> tracker [
	"The call context and its settings, such as how long a call runs before it counts as slow."

	^ tracker
]

{ #category : 'accessing' }
MCPSonificationBackend >> withoutSonification [

	^ backend withoutSonification
]
