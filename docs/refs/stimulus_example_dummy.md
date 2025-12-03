# Stimulus example dummy app reference

Use the stripped-down Maglev engine under `stimulus_example/` as the canonical reference for the modern Rails stack. Key files to compare when wiring Darwin:

- `stimulus_example/app/views/layouts/maglev/editor/application.html.erb` shows how helper-driven importmap tags and Turbo frames are composed.
- `stimulus_example/config/editor_importmap.rb` and `config/client_importmap.rb` demonstrate the dual importmaps pattern.
- `stimulus_example/app/assets/javascripts/maglev/editor/index.js` is the editor entry point that wires Turbo + Stimulus controllers; the client entry mirrors it.
- `stimulus_example/app/helpers/maglev/application_helper.rb` contains the helper methods that emit importmap tags and preload modules.

The dummy app bundled with the example is intentionally minimal but is a good comparison point for how the host layout pulls in the engine-managed assets without relying on the host's importmap.
