require './spec_helper'
require 'active_record'
require_relative '../../lib/migration_lock_timeout'

RSpec.describe ActiveRecord::Migration do

  describe '#migrate' do

    before(:each) do
      MigrationLockTimeout.configure do |config|
        config.default_timeout = 5
      end
    end

    describe 'change migration' do

      class AddFoo < ActiveRecord::Migration
        def change
          create_table :foo do |t|
            t.timestamps
          end
        end
      end

      it 'runs migrate up with timeout' do
        migration = AddFoo.new
        expect(ActiveRecord::Base.connection).to receive(:execute).
          with("SET LOCAL lock_timeout = '5s'")
        migration.migrate(:up)
      end

      it 'does not use timeout for down migration' do
        migration = AddFoo.new
        expect(ActiveRecord::Base.connection).not_to receive(:execute)
        migration.migrate(:down)
      end

      it 'allows migration to run if no default timeout set' do
        MigrationLockTimeout.config = nil
        migration = AddFoo.new
        expect(ActiveRecord::Base.connection).not_to receive(:execute)
        migration.migrate(:up)
      end
    end

    describe 'up / down migration' do

      class AddBar < ActiveRecord::Migration
        def up
          create_table :bar do |t|
            t.timestamps
          end
        end

        def down
          drop_table :bar
        end
      end

      it 'runs migrate up with timeout' do
        migration = AddBar.new
        expect(ActiveRecord::Base.connection).to receive(:execute).
          with("SET LOCAL lock_timeout = '5s'")
        migration.migrate(:up)
      end

      it 'does not use timeout for down migration' do
        migration = AddBar.new
        expect(ActiveRecord::Base.connection).not_to receive(:execute)
        migration.migrate(:down)
      end
    end

    describe 'disable lock timeout' do

      class AddBaz < ActiveRecord::Migration
        disable_lock_timeout!
        def up
          create_table :baz do |t|
            t.timestamps
          end
        end

        def down
          drop_table :baz
        end
      end

      it 'runs migrate up without timeout' do
        migration = AddBaz.new
        expect(ActiveRecord::Base.connection).not_to receive(:execute).
          with("SET LOCAL lock_timeout = '5s'")
        migration.migrate(:up)
      end

      it 'does not use timeout for down migration' do
        migration = AddBaz.new
        expect(ActiveRecord::Base.connection).not_to receive(:execute)
        migration.migrate(:down)
      end
    end

  end
end