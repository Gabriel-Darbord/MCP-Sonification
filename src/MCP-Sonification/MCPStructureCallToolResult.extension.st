Extension { #name : 'MCPStructureCallToolResult' }

{ #category : '*MCP-Sonification' }
MCPStructureCallToolResult >> sonificationData [
	"Test tools put failures, errors, and timeouts in their structured data. Other tools may answer anything, so check the shape at this boundary."

	| data |
	structuredContent isDictionary ifFalse: [ ^ Dictionary new ].
	data := structuredContent at: #data ifAbsent: [ ^ Dictionary new ].
	^ data isDictionary
		  ifTrue: [ data ]
		  ifFalse: [ Dictionary new ]
]

{ #category : '*MCP-Sonification' }
MCPStructureCallToolResult >> sonificationPhase [
	"The outcome of the tool call that answered me: error, timeout (test runs that ran out of time), failure (the call worked but reports failing tests), or success."

	| data |
	self isError ifTrue: [ ^ 'error' ].
	data := self sonificationData.
	(data includesKey: #timedOut) ifTrue: [ ^ 'timeout' ].
	^ (#( #failures #errors ) anySatisfy: [ :key | data includesKey: key ])
		  ifTrue: [ 'failure' ]
		  ifFalse: [ 'success' ]
]
