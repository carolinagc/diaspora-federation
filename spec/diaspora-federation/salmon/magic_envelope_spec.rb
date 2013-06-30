require 'spec_helper'

describe Salmon::MagicEnvelope do
  let(:payload) { Entities::TestEntity.new(test: 'asdf') }
  let(:pkey) { OpenSSL::PKey::RSA.generate(512) } # use small key for speedy specs
  let(:envelope) { Salmon::MagicEnvelope.new(pkey, payload).envelop }

  context 'sanity' do
    it 'constructs an instance' do
      expect { Salmon::MagicEnvelope.new(pkey, payload) }.not_to raise_error
    end

    it 'raises an error if the param types are wrong' do
      ['asdf', 1234, :test, false].each do |val|
        expect {
          Salmon::MagicEnvelope.new(val, val)
        }.to raise_error
      end
    end
  end

  context '#envelop' do
    subject { Salmon::MagicEnvelope.new(pkey, payload) }

    its(:envelop) { should be_an_instance_of Ox::Element }

    it 'returns a magic envelope of correct structure' do
      env = subject.envelop
      env.name.should eql('me:env')

      control = ['me:data', 'me:encoding', 'me:alg', 'me:sig']
      env.nodes.each do |node|
        control.should include(node.name)
        control.reject! { |i| i == node.name }
      end

      control.should be_empty
    end

    it 'signs the payload correctly' do
      env = subject.envelop

      data = Base64.urlsafe_decode64(env.locate('me:data').first.text)
      type = env.locate('me:data').first['type']
      enc = env.locate('me:encoding').first.text
      alg = env.locate('me:alg').first.text

      subj = [data, type, enc, alg].map { |i| Base64.urlsafe_encode64(i) }.join('.')
      sig = Base64.urlsafe_decode64(env.locate('me:sig').first.text)

      pkey.public_key.verify(OpenSSL::Digest::SHA256.new, sig, subj).should be_true
    end
  end

  context '::unenvelop' do
    context 'sanity' do
      it 'works with sane input' do
        expect {
          Salmon::MagicEnvelope.unenvelop(envelope, pkey.public_key)
        }.not_to raise_error
      end

      it 'raises an error if the param types are wrong' do
        ['asdf', 1234, :test, false].each do |val|
          expect {
            Salmon::MagicEnvelope.unenvelop(val, val)
          }.to raise_error
        end
      end

      it 'verifies the envelope structure' do
        expect {
          Salmon::MagicEnvelope.unenvelop(Ox::Element.new('asdf'), pkey.public_key)
        }.to raise_error Salmon::MagicEnvelope::InvalidEnvelope
      end

      it 'verifies the signature' do
        other_key = OpenSSL::PKey::RSA.generate(512)
        expect {
          Salmon::MagicEnvelope.unenvelop(envelope, other_key.public_key)
        }.to raise_error Salmon::MagicEnvelope::InvalidSignature
      end
    end

    it 'returns the original entity' do
      e = Salmon::MagicEnvelope.unenvelop(envelope, pkey.public_key)
      e.should be_an_instance_of Entities::TestEntity
      e.test.should eql('asdf')
    end
  end
end