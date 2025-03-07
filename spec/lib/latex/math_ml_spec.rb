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

describe Latex::MathMl do
  subject(:math_ml) do
    Latex::MathMl.new(latex:)
  end

  let(:latex) do
    '\sqrt{25}+12^{12}'
  end
  let(:mml_doc) do
    <<~XML
      <math xmlns="http://www.w3.org/1998/Math/MathML" display="inline">
        <msqrt>
          <mrow>
            <mn>25</mn>
          </mrow>
        </msqrt>
        <mo>+</mo>
        <msup>
          <mn>12</mn>
          <mrow>
            <mn>12</mn>
          </mrow>
        </msup>
      </math>
    XML
  end
  let(:service_url) { "http://get.mml.com" }
  let(:request_id)  { "0c0dad8c-7857-4447-ba1f-9f33a2f1debf" }
  let(:request_id_signature) { CanvasSecurity.sign_hmac_sha512(request_id) }

  describe "#parse" do
    it "delegates to Ritex::Parser" do
      expect_any_instance_of(Ritex::Parser).to receive(:parse).once
      math_ml.parse
    end

    context "when using mathman" do
      before do
        expect(MathMan).to receive(:url_for).at_least(:once).and_return(service_url)
        expect(MathMan).to receive(:use_for_mml?).at_least(:once).and_return(true)
        expect(RequestContextGenerator).to receive(:request_id).at_least(:once).and_return(request_id)
        expect(CanvasSecurity).to receive(:services_signing_secret).at_least(:once).and_return("wooper")
      end

      it "calls `CanvasHttp.get` with full url" do
        expect(CanvasHttp).to receive(:get)
          .with(service_url, {
                  "X-Request-Context-Id" => CanvasSecurity.base64_encode(request_id),
                  "X-Request-Context-Signature" => CanvasSecurity.base64_encode(request_id_signature)
                })
          .and_return(
            instance_double(Net::HTTPOK,
                            code: 200,
                            body: mml_doc)
          )

        math_ml.parse
      end

      context "when response status is not 200" do
        it "returns an empty string" do
          expect(CanvasHttp).to receive_messages(get: instance_double(Net::HTTPServerError,
                                                                      code: 500,
                                                                      body: mml_doc))
          expect(math_ml.parse).to be_empty
        end
      end

      context "integral request id" do
        let(:request_id) { 5 }

        it "doesn't throw an error" do
          expect(CanvasHttp).to receive(:get)
            .with(service_url, {
                    "X-Request-Context-Id" => CanvasSecurity.base64_encode("5"),
                    "X-Request-Context-Signature" => CanvasSecurity.base64_encode(CanvasSecurity.sign_hmac_sha512("5"))
                  })
            .and_return(
              instance_double(Net::HTTPOK,
                              code: 200,
                              body: mml_doc)
            )

          math_ml.parse
        end

        it "caches" do
          enable_cache do
            expect(CanvasHttp).to receive(:get).and_return(instance_double(Net::HTTPOK, code: 200, body: mml_doc)).once

            math_ml.parse
            math_ml.parse
          end
        end
      end
    end
  end
end
