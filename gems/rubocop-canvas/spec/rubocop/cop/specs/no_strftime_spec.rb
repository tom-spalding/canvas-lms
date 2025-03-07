# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

describe RuboCop::Cop::Specs::NoStrftime do
  subject(:cop) { described_class.new }

  it "disallows strftime" do
    offenses = inspect_source(%{
      describe "date stuff" do
        it 'should do date stuff' do
          next_year = 1.year.from_now.strftime("%Y")
        end
      end
    })
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/Avoid using strftime/)
    expect(offenses.first.severity.name).to eq(:warning)
  end
end
