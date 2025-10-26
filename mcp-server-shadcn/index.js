#!/usr/bin/env node

// ============================================================
// IMPORTS - Loading necessary modules
// ============================================================

// MCP SDK imports - these allow us to create an MCP server
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { 
  CallToolRequestSchema, 
  ListToolsRequestSchema 
} from '@modelcontextprotocol/sdk/types.js';

// Node.js built-in modules
import { execSync } from 'child_process';  // To run shell commands
import fs from 'fs';                        // File system operations
import path from 'path';                    // Path manipulation

// ============================================================
// SERVER SETUP - Creating the MCP server instance
// ============================================================

const server = new Server(
  {
    name: 'shadcn-mcp-server',     // Name that appears in Claude
    version: '1.0.0',               // Your server version
  },
  {
    capabilities: {
      tools: {},                    // This server provides "tools" to Claude
    },
  }
);

// ============================================================
// TOOL DEFINITIONS - What actions Claude can perform
// ============================================================

/**
 * This tells Claude what tools are available.
 * Claude will see these as actions it can take.
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      // Tool 1: Add a component
      {
        name: 'add_shadcn_component',
        description: 'Add a shadcn/ui component to the project',
        inputSchema: {
          type: 'object',
          properties: {
            component: {
              type: 'string',
              description: 'Name of the component to add (e.g., button, dialog, form)',
            },
            path: {
              type: 'string',
              description: 'Project directory path (absolute path)',
            },
          },
          required: ['component', 'path'],
        },
      },
      
      // Tool 2: Initialize shadcn
      {
        name: 'init_shadcn',
        description: 'Initialize shadcn/ui in a project',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Project directory path (absolute path)',
            },
          },
          required: ['path'],
        },
      },
      
      // Tool 3: List all components
      {
        name: 'list_shadcn_components',
        description: 'List all available shadcn/ui components',
        inputSchema: {
          type: 'object',
          properties: {},  // No parameters needed
        },
      },
    ],
  };
});

// ============================================================
// TOOL IMPLEMENTATION - What happens when Claude uses a tool
// ============================================================

/**
 * This handles the actual execution when Claude calls a tool.
 * It's like a switch statement that runs different code based on
 * which tool Claude wants to use.
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      // When Claude wants to add a component
      case 'add_shadcn_component': {
        const { component, path: projectPath } = args;
        
        // Run the shadcn CLI command
        // Example: npx shadcn-ui@latest add button
        const result = execSync(
          `npx shadcn-ui@latest add ${component} --yes`,
          { 
            cwd: projectPath,        // Run in the project directory
            encoding: 'utf-8',       // Return string output
            stdio: 'pipe'            // Capture output
          }
        );
        
        return {
          content: [
            {
              type: 'text',
              text: `✅ Successfully added ${component} component!\n\n${result}`,
            },
          ],
        };
      }

      // When Claude wants to initialize shadcn
      case 'init_shadcn': {
        const { path: projectPath } = args;
        
        // Check if already initialized
        const componentsJsonPath = path.join(projectPath, 'components.json');
        if (fs.existsSync(componentsJsonPath)) {
          return {
            content: [
              {
                type: 'text',
                text: '⚠️ shadcn/ui is already initialized in this project.',
              },
            ],
          };
        }
        
        // Run the init command
        const result = execSync(
          'npx shadcn-ui@latest init --yes --defaults',
          { 
            cwd: projectPath, 
            encoding: 'utf-8',
            stdio: 'pipe'
          }
        );
        
        return {
          content: [
            {
              type: 'text',
              text: `✅ Initialized shadcn/ui!\n\n${result}`,
            },
          ],
        };
      }

      // When Claude wants to see all available components
      case 'list_shadcn_components': {
        // This is the current list of shadcn components
        // You can update this list as shadcn adds new components
        const components = [
          'accordion', 'alert', 'alert-dialog', 'aspect-ratio', 'avatar',
          'badge', 'button', 'calendar', 'card', 'carousel', 'checkbox', 
          'collapsible', 'command', 'context-menu', 'dialog', 'drawer',
          'dropdown-menu', 'form', 'hover-card', 'input', 'input-otp',
          'label', 'menubar', 'navigation-menu', 'pagination', 'popover', 
          'progress', 'radio-group', 'resizable', 'scroll-area', 'select',
          'separator', 'sheet', 'skeleton', 'slider', 'sonner', 'switch', 
          'table', 'tabs', 'textarea', 'toast', 'toggle', 'toggle-group',
          'tooltip',
        ];
        
        return {
          content: [
            {
              type: 'text',
              text: `📦 Available shadcn/ui components (${components.length} total):\n\n${components.join(', ')}`,
            },
          ],
        };
      }

      // If Claude tries to use a tool that doesn't exist
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    // If something goes wrong, return an error message
    return {
      content: [
        {
          type: 'text',
          text: `❌ Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// ============================================================
// SERVER STARTUP - Connect to Claude and start listening
// ============================================================

/**
 * This starts the MCP server and connects it to Claude.
 * MCP uses "stdio" (standard input/output) for communication.
 */
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  
  // Log to stderr (not stdout) so it doesn't interfere with MCP protocol
  console.error('🚀 shadcn MCP server running on stdio');
}

// Run the server and handle any errors
main().catch((error) => {
  console.error('💥 Fatal error:', error);
  process.exit(1);
});
