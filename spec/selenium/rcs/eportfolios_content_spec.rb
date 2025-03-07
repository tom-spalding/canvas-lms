# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/eportfolios_common"

describe "add content box" do
  include_context "in-process server selenium tests"
  include EportfoliosCommon

  before do
    course_with_student_logged_in
    stub_rcs_config
    @assignment = @course.assignments.create(name: "new assignment")
    @assignment.submit_homework(@student)
    attachment_model(context: @student)
    eportfolio_model({ user: @user, name: "student content" })
    get "/eportfolios/#{@eportfolio.id}?view=preview"
    f("#right-side .edit_content_link").click
    wait_for_ajaximations
  end

  it "clicks on the How Do I..? button" do
    f(".wizard_popup_link").click
    expect(f("#wizard_box .wizard_options_list")).to be_displayed
  end

  it "previews rich text content" do
    skip("eportfolio still using old RCE, LS-1805")
    f(".add_rich_content_link").click
    type_in_tiny "textarea", "hello preview"
    fj('button:contains("Preview")').click
    expect(f(".preview_content.preview_section")).to include_text("hello preview")
  end

  it "adds rich text content" do
    skip("eportfolio still using old RCE, LS-1805")
    f(".add_rich_content_link").click
    type_in_tiny "textarea", "hello student"
    f("[data-testid='save-page']").click
    wait_for_ajax_requests
    entry_verifier({ section_type: "rich_text", content: "hello student" })
    expect(f("#page_content .section_content")).to include_text("hello student")
  end

  it "adds a user file" do
    skip("this only worked with the legacy editor. make it work w/ canvas-rce CORE-2714")
    expect(f(".add_file_link")).to be_displayed
    f(".add_file_link").click
    wait_for_ajaximations
    fj(".file_list:visible .sign:visible").click
    wait_for_ajaximations # my files
    file = fj("li.file .text:visible")
    expect(file).to include_text @attachment.filename
    wait_for_ajaximations
    file.click
    f(".upload_file_button").click
    wait_for_ajaximations
    download = fj(".eportfolio_download:visible")
    expect(download).to be_present
    expect(download).to include_text @attachment.filename
    f("[data-testid='save-page']").click
    wait_for_ajaximations
    expect(f(".section.read_only")).to include_text @attachment.filename
    refresh_page
    expect(f(".section.read_only")).to include_text @attachment.filename
  end

  context "adding html content" do
    before do
      @html_content = "<strong>student</strong>"
      f(".add_html_link").click
      wait_for_ajaximations
      f("#edit_page_section_0").send_keys(@html_content)
    end

    def add_html
      f("[data-testid='save-page']").click
    end

    def put_comment_in_html
      allow_comments = "#eportfolio_entry_allow_comments"
      f(allow_comments).click
      expect(is_checked(allow_comments)).to be_truthy
      comment_public = "#eportfolio_entry_show_comments"
      f(comment_public).click
      expect(is_checked(comment_public)).to be_truthy
      f("[data-testid='save-page']").click
      wait_for_ajaximations
      expect(f(".section_content strong").text).to eq "student"
      entry_verifier({ section_type: "html", content: @html_content })
      refresh_page
      f("#page_comment_message").send_keys("hi student")
      submit_form("#add_page_comment_form")
      wait_for_ajax_requests
      expect(f("#page_comments .message")).to include_text("hi student")
      expect(@eportfolio_entry.page_comments[0].message).to eq "hi student"
    end

    it "verifies that the html is there" do
      add_html
      expect(f(".section_content strong").text).to eq "student"
      entry_verifier({ section_type: "html", content: @html_content })
    end

    it "puts comment in html" do
      put_comment_in_html
    end

    it "deletes the html content" do
      add_html
      entry_verifier({ section_type: "html", content: @html_content })
      f("#right-side .edit_content_link").click
      hover_and_click("#page_section_0 .delete_page_section_link")
      accept_alert
      wait_for_ajaximations
      f("[data-testid='save-page']").click
      wait_for_ajaximations
      expect(@eportfolio.eportfolio_entries.first.content[0]).to eq "No Content Added Yet"
      expect(f("#content")).not_to contain_css("#edit_page_section_0")
    end

    it "deletes html comment" do
      put_comment_in_html
      expect(PageComment.count).to be > 0
      f(".delete_comment_link").click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css("#page_comments .message")
      expect(PageComment.count).to eq 0
    end
  end
end
