# Best Practices for Building Agents with Claude Agent SDK              
                                                                        
## Core Architecture Pattern                                            
                                                                        
The fundamental agent loop consists of three phases:                    
                                                                        
1. **Gather context** - Agents fetch and update their own context       
using available tools                                                   
2. **Take action** - Execute tasks through various execution            
methods                                                                 
3. **Verify work** - Evaluate outputs and iterate until                 
satisfactory                                                            
                                                                        
## Context Management Strategies                                        
                                                                        
**Agentic Search**: Leverage the file system as context                 
infrastructure. Agents use bash commands (`grep`, `tail`) to            
intelligently load relevant information rather than dumping entire      
files into context. "The folder and file structure of an agent          
becomes a form of context engineering."                                 
                                                                        
**Semantic Search**: Use vector-based retrieval as a secondary          
option when agentic search proves insufficient. Start with file         
system search first, then add semantic layers if performance            
demands it.                                                             
                                                                        
**Subagents**: Deploy multiple specialized agents working in            
parallel on isolated tasks. Subagents return only relevant excerpts     
 rather than full context, preventing context window bloat.             
                                                                        
**Context Compaction**: Automatically summarize conversation            
history as context limits approach, enabling long-running agents        
without memory degradation.                                             
                                                                        
## Tool Design Principles                                               
                                                                        
Tools should represent primary, high-frequency actions. According       
to the documentation, "tools are prominent in Claude's context          
window, making them the primary actions Claude will consider when       
deciding how to complete a task."                                       
                                                                        
Design considerations:                                                  
- Each tool should perform a clear, atomic function                     
- Prioritize most-used actions as dedicated tools                       
- Avoid tool proliferation that clutters the context window             
                                                                        
## Execution Methods (in order of preference)                           
                                                                        
**Custom Tools**: Define domain-specific operations like                
`fetchInbox` or `searchEmails` that align with your agent's primary     
 workflow.                                                              
                                                                        
**Bash & Scripts**: Enable flexible computer access for                 
general-purpose work—file manipulation, data processing, external       
command execution.                                                      
                                                                        
**Code Generation**: Express complex operations as executable code.     
 "Code is precise, composable, and infinitely reusable, making it       
an ideal output for agents."                                            
                                                                        
**Model Context Protocol (MCP)**: Integrate external services           
(Slack, GitHub, Asana) with standardized, pre-authenticated             
connections.                                                            
                                                                        
## Output Verification Strategies                                       
                                                                        
**Rules-Based Feedback**: Define explicit validation rules and          
return specific failures. Linting provides multi-layered feedback       
(TypeScript better than pure JavaScript).                               
                                                                        
**Visual Feedback**: For UI/layout tasks, provide screenshots or        
renders back to the model for iterative refinement, checking            
layout, styling, hierarchy, and responsiveness.                         
                                                                        
**LLM-as-Judge**: Deploy secondary models to evaluate fuzzy             
criteria (tone, quality, appropriateness), though this trades           
latency for marginal improvements.                                      
                                                                        
## Agent Evaluation & Improvement                                       
                                                                        
When agents underperform:                                               
- **Misunderstanding**: Restructure search APIs to surface needed       
information                                                             
- **Repeated failures**: Add formal validation rules in tool calls      
- **Limited capability**: Provide additional or more creative tools     
- **Variable performance**: Build representative test sets for          
programmatic evaluation                                                 
                                                                        
## Key Design Philosophy                                                
                                                                        
"Give your agents a computer, allowing them to work like humans         
do." This principle—providing access to files, terminals, and           
integrated tools—transforms agents from simple chatbots into            
autonomous workers capable of complex, iterative problem-solving        
across multiple domains. 
