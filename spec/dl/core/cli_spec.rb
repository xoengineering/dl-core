require 'tmpdir'
require_relative '../../support/example_dl'

RSpec.describe DL::Core::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  def run_with arguments, stdin: StringIO.new
    ExampleDL::CLI.new(arguments, stderr: stderr, stdin: stdin, stdout: stdout).run
  end

  def with_env vars
    previous = vars.to_h { |key, _| [key.to_s, ENV.fetch(key.to_s, nil)] }
    vars.each { |key, value| ENV[key.to_s] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end

  context 'when a gem does not define what the CLI needs' do
    it 'names the missing method' do
      expect { described_class.new(['42'], stderr:, stdout:).run }
        .to raise_error NotImplementedError, 'DL::Core::CLI must define #program'
    end
  end

  describe '#run' do
    context 'with a target and -p path' do
      it 'archives it, prints its folder, and returns 0' do
        Dir.mktmpdir do |root|
          expect(run_with(['-p', root, '--rate-limit', '0', '42'])).to eq 0
          expect(stdout.string).to eq "#{File.join(root, '42')}\n"
          expect(File.read(File.join(root, '42', 'paper.txt'))).to eq 'paper 42'
        end
      end
    end

    context 'with -q (quiet)' do
      it 'prints nothing on success' do
        Dir.mktmpdir do |root|
          run_with ['-p', root, '-q', '42']

          expect(stdout.string).to be_empty
        end
      end
    end

    context 'with -v (verbose)' do
      it 'prints a step line per target' do
        Dir.mktmpdir do |root|
          run_with ['-p', root, '-v', '42']

          expect(stdout.string).to include '==> Downloading 42'
        end
      end
    end

    context 'with -v and -q together' do
      it 'exits non-zero with an error on stderr' do
        expect(run_with(['-v', '-q', '42'])).to eq 1
        expect(stderr.string).to eq "-v and -q are mutually exclusive\n"
      end
    end

    context 'with --version' do
      it "prints the gem's version and exits 0" do
        expect(run_with(['--version'])).to eq 0
        expect(stdout.string).to eq "1.2.3\n"
      end
    end

    context 'with -h' do
      it "prints help with the gem's usage line and exits 0" do
        expect(run_with(['-h'])).to eq 0
        expect(stdout.string).to start_with 'Usage: example-dl [options] <EXAMPLE_ID> [<EXAMPLE_ID>...]'
      end
    end

    context 'with no targets' do
      it 'prints usage to stderr and exits non-zero' do
        expect(run_with([])).to eq 1
        expect(stderr.string).to start_with 'Usage: example-dl'
      end
    end

    context 'with an unknown option' do
      it 'reports it and exits non-zero' do
        expect(run_with(['--nope'])).to eq 1
        expect(stderr.string).to include '--nope'
      end
    end

    context 'with --input FILE' do
      it 'reads targets one per line, skipping blanks and # comments, combined with argument targets' do
        Dir.mktmpdir do |root|
          input = File.join root, 'targets.txt'
          File.write input, "# reading list\n\n1\n2\n"

          run_with ['-p', root, '--input', input, '3']

          expect(stdout.string.lines.map(&:chomp)).to eq(%w[3 1 2].map { File.join root, it })
        end
      end

      it 'exits non-zero when the file does not exist' do
        expect(run_with(['--input', '/nonexistent/targets.txt'])).to eq 1
        expect(stderr.string).to include '/nonexistent/targets.txt'
      end
    end

    context 'with --input -' do
      it 'reads targets from stdin' do
        Dir.mktmpdir do |root|
          run_with ['-p', root, '--input', '-'], stdin: StringIO.new("7\n")

          expect(stdout.string).to eq "#{File.join(root, '7')}\n"
        end
      end
    end

    context 'when some targets fail' do
      it 'reports each on stderr prefixed by its target, keeps going, and exits non-zero' do
        Dir.mktmpdir do |root|
          status = run_with ['-p', root, 'nope', '404', '42']

          expect(status).to eq 1
          expect(stdout.string).to eq "#{File.join(root, '42')}\n"
          expect(stderr.string.lines).to eq [
            "nope: not an example ID: nope\n",
            "404: GET https://example.org/404 failed: 404\n"
          ]
        end
      end
    end

    context 'with ENV <PREFIX>_DOWNLOAD_PATH and <PREFIX>_RATE_LIMIT' do
      it 'uses ENV when the flags are not given; flags win over ENV' do
        Dir.mktmpdir do |env_root|
          Dir.mktmpdir do |flag_root|
            with_env EXAMPLE_DOWNLOAD_PATH: env_root, EXAMPLE_RATE_LIMIT: '0' do
              run_with ['1']
              run_with ['-p', flag_root, '2']
            end

            expect(File).to     exist File.join(env_root, '1', 'paper.txt')
            expect(File).to     exist File.join(flag_root, '2', 'paper.txt')
            expect(File).not_to exist File.join(env_root, '2')
          end
        end
      end
    end
  end
end
