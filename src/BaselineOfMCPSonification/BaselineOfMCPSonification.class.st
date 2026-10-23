"
I load MCP-Sonification: an MCP observability hook that turns Pharo MCP tool calls into SoundBank events, with the context of each call, and the banks that play them.

	Metacello new
		githubUser: 'Gabriel-Darbord' project: 'MCP-Sonification' commitish: 'main' path: 'src';
		baseline: 'MCPSonification';
		load.

Groups: Core, Tests, and default (both). Depends on MCP and SoundBank (and through it, Scsynth).
"
Class {
	#name : 'BaselineOfMCPSonification',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfMCPSonification',
	#package : 'BaselineOfMCPSonification'
}

{ #category : 'baselines' }
BaselineOfMCPSonification >> baseline: spec [

	<baseline>
	spec for: #common do: [
			self defineDependencies: spec.
			self definePackages: spec.
			self defineGroups: spec ]
]

{ #category : 'baselines' }
BaselineOfMCPSonification >> defineDependencies: spec [

	spec baseline: 'MCP' with: [
			spec
				repository: 'github://Evref-BL/MCP:main/src';
				loads: #( 'Core' ) ].
	spec baseline: 'SoundBank' with: [
			spec
				repository: 'github://Gabriel-Darbord/SoundBank:main/src';
				loads: #( 'Core' ) ]
]

{ #category : 'baselines' }
BaselineOfMCPSonification >> defineGroups: spec [

	spec
		group: 'Core' with: #( 'MCP-Sonification' );
		group: 'Tests' with: #( 'MCP-Sonification-Tests' );
		group: 'default' with: #( 'Core' 'Tests' )
]

{ #category : 'baselines' }
BaselineOfMCPSonification >> definePackages: spec [

	spec
		package: 'MCP-Sonification' with: [ spec requires: #( 'MCP' 'SoundBank' ) ];
		package: 'MCP-Sonification-Tests' with: [ spec requires: #( 'MCP-Sonification' ) ]
]
