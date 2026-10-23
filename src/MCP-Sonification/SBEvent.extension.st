Extension { #name : 'SBEvent' }

{ #category : '*MCP-Sonification' }
SBEvent class >> tool: anMCPTool phases: somePhases [

	^ self
		  toolNamed: anMCPTool name
		  group: anMCPTool groupName
		  readOnly: anMCPTool annotations readOnlyHint = true
		  phases: somePhases
]

{ #category : '*MCP-Sonification' }
SBEvent class >> toolNamed: aToolName group: aGroupName readOnly: isReadOnly phases: somePhases [
	"Subjects from most to least specific: the tool, its group, read or write, anything."

	^ self
		  subjects: {
				  aToolName.
				  aGroupName.
				  (isReadOnly
					   ifTrue: [ 'read' ]
					   ifFalse: [ 'write' ]).
				  '*' }
		  phases: somePhases
]

{ #category : '*MCP-Sonification' }
SBEvent class >> unknownToolNamed: aToolName phases: somePhases [

	^ self
		  subjects: {
				  aToolName.
				  '*' }
		  phases: somePhases
]
