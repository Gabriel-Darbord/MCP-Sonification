"
I test the observability decorator on an unstarted MCP. I act as the engine myself: I record posted events and reported errors.
"
Class {
	#name : 'MCPSonificationBackendTest',
	#superclass : 'TestCase',
	#instVars : [
		'mcp',
		'posted',
		'reported'
	],
	#category : 'MCP-Sonification-Tests',
	#package : 'MCP-Sonification-Tests'
}

{ #category : 'helpers' }
MCPSonificationBackendTest >> call: aToolName on: aBackend result: aToolResult error: anError [

	| record |
	record := aBackend
		          recordToolCallStart: aToolName
		          input: Dictionary new
		          dispatchPath: 'direct'
		          context: Dictionary new.
	aBackend recordToolCallFinish: record result: aToolResult error: anError
]

{ #category : 'helpers' }
MCPSonificationBackendTest >> decorator [

	^ MCPSonificationBackend on: mcp ensureLocalObservabilityBackend engine: self toolRegistry: mcp toolRegistry
]

{ #category : 'soundboard' }
MCPSonificationBackendTest >> post: anEvent [

	posted add: anEvent
]

{ #category : 'helpers' }
MCPSonificationBackendTest >> postedNames [

	^ (posted collect: [ :event | event name ]) asArray
]

{ #category : 'helpers' }
MCPSonificationBackendTest >> postedNamesAfter: aDuration [
	"Waiting events are posted from another process."

	aDuration wait.
	^ self postedNames
]

{ #category : 'soundboard' }
MCPSonificationBackendTest >> reportError: anError [

	reported add: anError
]

{ #category : 'running' }
MCPSonificationBackendTest >> setUp [

	super setUp.
	mcp := MCP new.
	posted := OrderedCollection new.
	reported := OrderedCollection new
]

{ #category : 'helpers' }
MCPSonificationBackendTest >> start: aToolName on: aBackend [

	^ aBackend
		  recordToolCallStart: aToolName
		  input: Dictionary new
		  dispatchPath: 'direct'
		  context: Dictionary new
]

{ #category : 'helpers' }
MCPSonificationBackendTest >> successResult [

	^ MCPStructureCallToolResult content: 'done'
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testAttachAndDetach [

	| local engine |
	local := mcp ensureLocalObservabilityBackend.
	engine := SBEngine new.
	MCPSonificationBackend attachEngine: engine to: mcp.
	self assert: mcp observability engine identicalTo: engine.
	self assert: mcp observability backend identicalTo: local.
	MCPSonificationBackend attachEngine: engine to: mcp.
	self assert: mcp observability backend identicalTo: local.
	MCPSonificationBackend detachFrom: mcp.
	self assert: mcp observability identicalTo: local.
	MCPSonificationBackend detachFrom: mcp.
	self assert: mcp observability identicalTo: local
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testCallsWithoutRecordsPostNoFinish [

	| decorator |
	decorator := self decorator.
	decorator recordToolCallFinish: nil result: self successResult error: nil.
	self assert: posted isEmpty
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testCleanTestRunPostsSuccess [

	self
		call: 'test_run'
		on: self decorator
		result: (self testRunResultWith: nil)
		error: nil.
	self assert: self postedNames last equals: 'test_run.success'
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testErrorResultPostsError [

	self
		call: 'class_get'
		on: self decorator
		result: MCPStructureErrorToolResult new
		error: nil.
	self assert: self postedNames last equals: 'class_get.error'
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testFailingCallPostsError [

	self
		call: 'method_compile'
		on: self decorator
		result: nil
		error: (Error new messageText: 'boom').
	self assert: self postedNames equals: #( 'method_compile.start' 'method_compile.error' ).
	self assert: (posted last keys includes: 'write.error')
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testLongCallsPostWaiting [

	| decorator record |
	decorator := self decorator.
	decorator tracker waitingDelay: 50 milliSeconds.
	record := self start: 'method_search' on: decorator.
	self assert: ((self postedNamesAfter: 200 milliSeconds) includes: 'method_search.waiting').
	decorator recordToolCallFinish: record result: self successResult error: nil.
	self assert: self postedNames last equals: 'method_search.success'
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testQuickCallsDoNotPostWaiting [

	| decorator |
	decorator := self decorator.
	decorator tracker waitingDelay: 50 milliSeconds.
	self
		call: 'class_get'
		on: decorator
		result: self successResult
		error: nil.
	self deny: ((self postedNamesAfter: 200 milliSeconds) includes: 'class_get.waiting')
]

{ #category : 'helpers' }
MCPSonificationBackendTest >> testRunResultWith: aProblem [
	"A test_run result reporting aProblem (#failures, #errors, or #timedOut), or a clean run for nil."

	| data |
	data := Dictionary new
		        at: #runCount put: 2;
		        at: #passedCount put: (aProblem ifNil: [ 2 ] ifNotNil: [ 1 ]);
		        yourself.
	aProblem ifNotNil: [ data at: aProblem put: #( 'something' ) ].
	^ self testRunResultWithData: data
]

{ #category : 'helpers' }
MCPSonificationBackendTest >> testRunResultWithData: aDictionary [

	^ (MCPStructureCallToolResult content: 'tests ran')
		  structuredContent: (Dictionary new
				   at: #summary put: 'tests ran';
				   at: #data put: aDictionary;
				   yourself);
		  yourself
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testSecondFailureInARowIsRepeated [

	| decorator |
	decorator := self decorator.
	self
		call: 'method_compile'
		on: decorator
		result: nil
		error: Error new.
	self assert: posted last phases equals: #( 'error' ).
	self
		call: 'class_get'
		on: decorator
		result: MCPStructureErrorToolResult new
		error: nil.
	self assert: posted last phases equals: #( 'repeated-failure' 'error' ).
	self
		call: 'class_get'
		on: decorator
		result: self successResult
		error: nil.
	self assert: posted last phases equals: #( 'recovered' 'success' )
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testSoundFailuresDoNotBreakTheCall [
	"I am also the tool registry here, and I am broken."

	| decorator |
	decorator := MCPSonificationBackend on: mcp ensureLocalObservabilityBackend engine: self toolRegistry: self.
	self
		call: 'class_get'
		on: decorator
		result: self successResult
		error: nil.
	self assert: posted isEmpty.
	self assert: reported size equals: 2.
	self assert: decorator totalCallCount equals: 1
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testSuccessAfterAFailureOfTheSameToolIsRecovered [

	| decorator |
	decorator := self decorator.
	self
		call: 'test_run'
		on: decorator
		result: (self testRunResultWith: #failures)
		error: nil.
	self
		call: 'class_get'
		on: decorator
		result: self successResult
		error: nil.
	self assert: posted last phases equals: #( 'success' ).
	self
		call: 'test_run'
		on: decorator
		result: (self testRunResultWith: nil)
		error: nil.
	self assert: posted last phases equals: #( 'recovered' 'success' ).
	self assert: self postedNames last equals: 'test_run.recovered'
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testSuccessfulCallPostsStartAndSuccess [

	self
		call: 'class_get'
		on: self decorator
		result: self successResult
		error: nil.
	self assert: self postedNames equals: #( 'class_get.start' 'class_get.success' ).
	self assert: posted last keys equals: #( 'class_get.success' 'classes.success' 'read.success' '*.success' )
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testTestRunWithProblemsPostsFailure [

	#( #failures #errors ) do: [ :problem |
			posted removeAll.
			self
				call: 'test_run'
				on: self decorator
				result: (self testRunResultWith: problem)
				error: nil.
			self assert: self postedNames last equals: 'test_run.failure'.
			self assert: (posted last keys includes: 'tests.failure') ]
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testTimedOutTestRunPostsTimeoutThenFailure [

	self
		call: 'test_run'
		on: self decorator
		result: (self testRunResultWith: #timedOut)
		error: nil.
	self assert: posted last phases equals: #( 'timeout' 'failure' )
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testToolCallWrapperPostsNothing [

	self
		call: 'tool_call'
		on: self decorator
		result: self successResult
		error: nil.
	self assert: posted isEmpty
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testUnknownToolStillPosts [

	self
		call: 'not_a_tool'
		on: self decorator
		result: self successResult
		error: nil.
	self assert: posted last keys equals: #( 'not_a_tool.success' '*.success' )
]

{ #category : 'tests' }
MCPSonificationBackendTest >> testWrappedBackendStillRecords [

	| decorator |
	decorator := self decorator.
	self
		call: 'class_get'
		on: decorator
		result: self successResult
		error: nil.
	self
		call: 'class_get'
		on: decorator
		result: nil
		error: Error new.
	self assert: decorator totalCallCount equals: 2.
	self assert: decorator totalErrorCount equals: 1.
	self assert: decorator backend totalCallCount equals: 2.
	self assert: decorator recentCallRecords size equals: 2.
	self deny: decorator isNoop
]

{ #category : 'tool registry' }
MCPSonificationBackendTest >> toolNamed: aToolName ifAbsent: aBlock [
	"I stand in for a broken tool registry."

	^ self error: 'Broken registry'
]
