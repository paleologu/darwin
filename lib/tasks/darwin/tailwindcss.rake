# frozen_string_literal: true

namespace :darwin do
  namespace :tailwindcss do
    desc 'Generate Tailwind CSS classes from component files'
    task build: :environment do
      puts '[Darwin] Building EditorTailwind CSS'
      run_tailwindcss_cli
    end

    desc 'Watch for changes in component files and rebuild Tailwind CSS'
    task watch: :environment do
      run_tailwindcss_cli('--watch')
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def run_tailwindcss_cli(options = nil)
      command_path = Darwin::Engine.root.join('exe', 'tailwind-cli')
      erb_input_path = Darwin::Engine.root.join('app/assets/stylesheets/darwin/tailwind.css.erb')
      input_path     = erb_input_path.dirname.join('maglev-compiled-tailwind.css') # same dir as ERB
      output_path = Darwin::Engine.root.join('app/assets/builds/darwin/tailwind.css')


      puts "[Darwin] command_path:   #{command_path}"
      puts "[Darwin] erb_input_path: #{erb_input_path} (exists? #{File.exist?(erb_input_path)})"
      puts "[Darwin] input_path:     #{input_path}"
      puts "[Darwin] output_path:    #{output_path}"
      puts "[Darwin] Darwin::Engine.root: #{Darwin::Engine.root}"


      FileUtils.mkdir_p(input_path.dirname)

      puts "[Darwin] Generating temporary Tailwind input file at: #{input_path}"


      puts "[Darwin] Rendering ERB input..."
      rendered_css = ERB.new(File.read(erb_input_path)).result
      puts "[Darwin] Rendered CSS length: #{rendered_css.length}"
      puts "[Darwin] Rendered CSS preview:\n#{rendered_css[0, 300]}"


      File.delete(input_path) if File.exist?(input_path)
      File.write(input_path, rendered_css)

  puts "[Darwin] Wrote temp file? #{File.exist?(input_path)} (size: #{File.size(input_path)} bytes)"

      require 'bundler'
      Bundler.with_unbundled_env do
      cmd = [
      command_path.to_s,
      '-i', input_path.to_s,
      '-o', output_path.to_s
    ]
    cmd << options.to_s if options

        puts "[Darwin] Running command: #{cmd.join(' ')}"
    success = system(*cmd)
    puts "[Darwin] Command finished. success=#{success.inspect}, exitstatus=#{$?.exitstatus if $?}"
    puts "[Darwin] Output file exists? #{File.exist?(output_path)}"
    puts "[Darwin] Output file size: #{File.size(output_path)} bytes" if File.exist?(output_path)
        #system "#{command_path} -i #{input_path} -o #{output_path} #{options}"

      File.delete(input_path) if File.exist?(input_path)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
