# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
#

#
# some if the specs in here include "ignore_js_errors: true". This is because
# console errors are emitted for things that aren't really errors, like react
# jsx attribute type warnings
#

require_relative "../common"
require_relative "pages/block_editor_page"

describe "Block Editor", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockEditorPage

  # a default page that's had an apple icon block added
  let(:block_page_content) do
    file = File.open(File.expand_path(File.dirname(__FILE__) + "/../../fixtures/block-editor/page-with-apple-icon.json"))
    file.read
  end

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_editor)
    @course.account.enable_feature!(:block_template_editor)
    @context = @course
    @block_page = @course.wiki_pages.create!(title: "Block Page")

    @block_page.update!(
      block_editor_attributes: {
        time: Time.now.to_i,
        version: "0.2",
        blocks: block_page_content
      }
    )
  end

  describe "Top bar actions in the block editor" do
    it "can preview a page and close the preview modal" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      expect(columns_section).to be_displayed

      icon_block.click
      expect(block_toolbar).to be_displayed

      top_bar_action("preview").click
      expect(icon_block).to be_displayed
      expect(preview_modal_background_image).to be_displayed
      preview_modal_close_button.click
      expect(block_toolbar).to be_displayed
    end

    it "can undo an action" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      expect(columns_section).to be_displayed

      icon_block.click
      expect(block_toolbar).to be_displayed
      f(block_toolbar_selector("delete")).click
      expect(body).not_to contain_css('[data-testid="icon-block"]')

      editor_area.click
      top_bar_action("undo").click
      expect(icon_block).to be_displayed
    end

    it "can redo an action" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      expect(columns_section).to be_displayed

      icon_block.click
      expect(block_toolbar).to be_displayed
      f(block_toolbar_selector("delete")).click
      expect(body).not_to contain_css('[data-testid="icon-block"]')

      editor_area.click
      top_bar_action("undo").click
      expect(icon_block).to be_displayed

      editor_area.click
      top_bar_action("redo").click
      expect(body).not_to contain_css('[data-testid="icon-block"]')
    end
  end
end
