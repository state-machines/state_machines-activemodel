# frozen_string_literal: true

# Use lazy evaluation to avoid circular dependencies with frozen default_messages
# This ensures messages can be updated after gem loading while maintaining thread safety
{ en: {
  activemodel: {
    errors: {
      messages: {
        invalid: lambda { |*| StateMachines::Machine.default_messages[:invalid] },
        invalid_event: lambda { |*| StateMachines::Machine.default_messages[:invalid_event] % ['%{state}'] },
        invalid_transition: lambda { |*| StateMachines::Machine.default_messages[:invalid_transition] % ['%{event}'] }
      }
    }
  }
} }
