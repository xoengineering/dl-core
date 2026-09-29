RSpec.describe DL::Core::Client do
  let(:user_agent) { 'example-dl/1.2.3 (+https://github.com/xoengineering/example-dl)' }

  describe '#user_agent' do
    it 'is the one the gem passed in' do
      expect(described_class.new(user_agent:).user_agent).to eq user_agent
    end
  end

  describe '#rate_limit' do
    context 'with no argument' do
      it 'defaults to 3 seconds' do
        expect(described_class.new(user_agent:).rate_limit).to eq 3
      end
    end

    context 'with an explicit interval' do
      it 'returns the configured interval' do
        expect(described_class.new(user_agent:, rate_limit: 1).rate_limit).to eq 1
      end
    end

    context 'with zero (disabled)' do
      it 'returns 0' do
        expect(described_class.new(user_agent:, rate_limit: 0).rate_limit).to eq 0
      end
    end
  end

  describe '#get' do
    let(:client) { described_class.new(user_agent:, rate_limit: 0) }
    let(:url)    { 'https://archive.org/metadata/jstor-4385670' }
    let(:body)   { File.read 'spec/fixtures/http/archive-org-metadata.json' }

    before { stub_request(:get, url).to_return(status: 200, body: body) }

    it 'returns the response body' do
      expect(client.get(url).to_s).to eq body
    end

    it 'sets connect, read, and write timeouts so a stalled connection cannot hang forever' do
      allow(HTTP).to receive(:timeout).and_call_original

      client.get url

      expect(HTTP).to have_received(:timeout).with(connect: 10, read: 60, write: 10)
    end

    it 'sends the gem User-Agent header' do
      client.get url

      expect(WebMock).to have_requested(:get, url).with(headers: { 'User-Agent' => client.user_agent })
    end

    context 'when the server responds with a non-success status' do
      before { stub_request(:get, url).to_return(status: 404) }

      it 'raises HTTPError with the status and URL' do
        expect { client.get url }.to raise_error(DL::Core::HTTPError) { |error|
          expect(error.status).to  eq 404
          expect(error.url).to     eq url
          expect(error.message).to eq "GET #{url} failed: 404 Not Found"
        }
      end

      it 'still logs the request' do
        log = StringIO.new

        expect { described_class.new(user_agent:, rate_limit: 0, log: log).get url }.to raise_error DL::Core::HTTPError
        expect(log.string).to include "==> GET #{url}"
      end
    end

    context 'when the server is throttling (429) or unavailable (503)' do
      before { allow(client).to receive(:sleep) }

      it 'retries after a backoff and returns the eventual success' do
        stub_request(:get, url).to_return({ status: 429 }, { status: 200, body: body })

        expect(client.get(url).to_s).to eq body
        expect(client).to have_received(:sleep).with(10).once
      end

      it 'doubles the backoff on each retry' do
        stub_request(:get, url).to_return({ status: 503 }, { status: 503 }, { status: 503 }, { status: 200, body: body })

        client.get url

        expect(client).to have_received(:sleep).with(10).ordered
        expect(client).to have_received(:sleep).with(20).ordered
        expect(client).to have_received(:sleep).with(40).ordered
      end

      it 'waits for Retry-After seconds when the server sends it' do
        stub_request(:get, url).to_return({ status: 503, headers: { 'Retry-After' => '7' } }, { status: 200, body: body })

        client.get url

        expect(client).to have_received(:sleep).with(7).once
      end

      it 'gives up with HTTPError after 3 retries' do
        stub_request(:get, url).to_return(status: 429)

        expect { client.get url }.to raise_error(DL::Core::HTTPError) { expect(it.status).to eq 429 }
        expect(WebMock).to have_requested(:get, url).times(4)
      end

      it 'logs each retry' do
        log    = StringIO.new
        client = described_class.new(user_agent:, rate_limit: 0, log: log)
        allow(client).to receive(:sleep)
        stub_request(:get, url).to_return({ status: 429 }, { status: 200, body: body })

        client.get url

        expect(log.string).to include '==> 429 Too Many Requests. Retrying in 10s'
      end

      it 'does not retry other failures' do
        stub_request(:get, url).to_return(status: 500)

        expect { client.get url }.to raise_error DL::Core::HTTPError
        expect(WebMock).to have_requested(:get, url).once
      end
    end

    context 'with rate-limiting enabled' do
      let(:client) { described_class.new(user_agent:, rate_limit: 3) }

      it 'does not sleep on the first request' do
        allow(client).to receive(:sleep)

        client.get url

        expect(client).not_to have_received(:sleep)
      end

      it 'sleeps before the second request to maintain the interval' do
        allow(client).to receive(:sleep)

        client.get url
        client.get url

        expect(client).to have_received(:sleep) do |seconds|
          expect(seconds).to be_positive
          expect(seconds).to be <= 3
        end
      end
    end

    context 'with rate-limiting disabled (rate_limit: 0)' do
      let(:client) { described_class.new(user_agent:, rate_limit: 0) }

      it 'never sleeps' do
        allow(client).to receive(:sleep)

        client.get url
        client.get url

        expect(client).not_to have_received(:sleep)
      end
    end

    context 'with a log sink' do
      it 'writes a step line per request with URL and byte count' do
        log = StringIO.new
        described_class.new(user_agent:, rate_limit: 0, log: log).get url

        expect(log.string).to include "==> GET #{url}"
        expect(log.string).to include "(#{body.bytesize} bytes)"
      end
    end
  end
end
