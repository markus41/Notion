# Interactive Components Demo

Test page to validate CodePlayground and NavigationMega components.

## CodePlayground Demo

### Simple TypeScript Example

<CodePlayground
  :files="[
    {
      name: 'hello.ts',
      language: 'typescript',
      content: 'console.log(\"Hello from Agent Studio!\");\nconsole.log(\"Interactive code execution works!\");\n\nconst greeting = \"Welcome to the playground\";\nconsole.log(greeting);'
    }
  ]"
  :runnable="true"
/>

### Multi-File Example

<CodePlayground
  :files="[
    {
      name: 'agent.ts',
      language: 'typescript',
      content: `interface Agent {\n  id: string;\n  name: string;\n  execute(): string;\n}\n\nclass TestAgent implements Agent {\n  constructor(public id: string, public name: string) {}\n\n  execute(): string {\n    return \`Agent \${this.name} executed successfully\`;\n  }\n}\n\nconst agent = new TestAgent('001', 'Test');\nconsole.log(agent.execute());`
    },
    {
      name: 'config.json',
      language: 'json',
      content: '{\n  \"agentId\": \"001\",\n  \"name\": \"TestAgent\",\n  \"version\": \"1.0.0\"\n}'
    }
  ]"
  :activeFile="0"
  :runnable="true"
/>

## NavigationMega Demo

Click the button below to open the mega navigation menu:

<NavigationMega :showSearch="true" :showFooter="true" />

---

**Status**: All components rendered successfully if you can see interactive elements above.
