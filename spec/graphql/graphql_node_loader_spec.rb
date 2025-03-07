# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe GraphQLNodeLoader do
  before :once do
    @account = Account.default
    @admin = account_admin_user(account: @account)
  end

  let!(:outcome) { outcome_model(context: @account) }
  let!(:outcome_group) { outcome_group_model(context: @account) }
  let!(:context) { { current_user: @admin } }
  let!(:user_without_permisssion) { user_model }

  def load_outcome(id, ctx = context)
    GraphQLNodeLoader.load("LearningOutcome", id, ctx)
  end

  def load_outcome_group(id, ctx = context)
    GraphQLNodeLoader.load("LearningOutcomeGroup", id, ctx)
  end

  describe ".load" do
    describe "LearningOutcome" do
      it "returns outcome if valid outcome id" do
        GraphQL::Batch.batch do
          load_outcome(outcome.id).then do |result|
            expect(result).not_to be_nil
            expect(result.id).to eq outcome.id
          end
        end
      end

      it "returns nil if invalid outcome id" do
        GraphQL::Batch.batch do
          load_outcome("9999999").then do |result|
            expect(result).to be_nil
          end
        end
      end

      context "for user without permission" do
        it "returns nil" do
          ctx = { current_user: user_without_permisssion }
          GraphQL::Batch.batch do
            load_outcome(outcome.id, ctx).then do |result|
              expect(result).to be_nil
            end
          end
        end
      end
    end

    describe "LearningOutcomeGroup" do
      it "returns outcome group if valid group id" do
        GraphQL::Batch.batch do
          load_outcome_group(outcome_group.id).then do |result|
            expect(result).not_to be_nil
            expect(result.id).to eq outcome_group.id
          end
        end
      end

      it "returns nil if invalid group id" do
        GraphQL::Batch.batch do
          load_outcome_group("9999999").then do |result|
            expect(result).to be_nil
          end
        end
      end

      context "for user without permission" do
        it "returns nil" do
          ctx = { current_user: user_without_permisssion }
          GraphQL::Batch.batch do
            load_outcome_group(outcome_group.id, ctx).then do |result|
              expect(result).to be_nil
            end
          end
        end
      end
    end

    describe "EnrollmentTerm" do
      it "returns nil if invalid sis id" do
        GraphQL::Batch.batch do
          GraphQLNodeLoader.load("TermBySis", "garbage", context).then do |result|
            expect(result).to be_nil
          end
        end
      end
    end

    describe "SubmissionByAssignmentAndUser" do
      let!(:course) { course_model }
      let!(:teacher) { teacher_in_course(active_all: true, course:).user }
      let!(:student) { student_in_course(active_all: true, course:).user }
      let(:context) { { current_user: teacher } }
      let!(:assignment) { assignment_model(course:, anonymous_grading: true) }

      it "does not return a submission for a teacher if the assignment is actively anonymous" do
        GraphQL::Batch.batch do
          GraphQLNodeLoader.load("SubmissionByAssignmentAndUser",
                                 { assignment_id: assignment.id, user_id: student.id },
                                 context).then do |result|
            expect(result).to be_nil
          end
        end
      end

      it "does return a submission for a teacher if the assignment is not actively anonymous" do
        assignment.submissions.update_all(workflow_state: :graded, posted_at: 1.day.ago)

        GraphQL::Batch.batch do
          GraphQLNodeLoader.load("SubmissionByAssignmentAndUser",
                                 { assignment_id: assignment.id, user_id: student.id },
                                 context).then do |result|
            expect(result).not_to be_nil
          end
        end
      end

      it "does return a submission to a teacher for a non-anonymous assignment" do
        assignment.update!(anonymous_grading: false)

        GraphQL::Batch.batch do
          GraphQLNodeLoader.load("SubmissionByAssignmentAndUser",
                                 { assignment_id: assignment.id, user_id: student.id },
                                 context).then do |result|
            expect(result).not_to be_nil
          end
        end
      end

      it "does return a submission to a student for an assignment" do
        GraphQL::Batch.batch do
          GraphQLNodeLoader.load("SubmissionByAssignmentAndUser",
                                 { assignment_id: assignment.id, user_id: student.id },
                                 { current_user: student }).then do |result|
            expect(result).not_to be_nil
          end
        end
      end
    end
  end
end
