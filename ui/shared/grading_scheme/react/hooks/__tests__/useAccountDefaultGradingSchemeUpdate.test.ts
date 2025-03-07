/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useAccountDefaultGradingSchemeUpdate} from '../useAccountDefaultGradingSchemeUpdate'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {ApiCallStatus} from '../ApiCallStatus'

import {renderHook} from '@testing-library/react-hooks/dom'

const accountId = '42'

jest.mock('@canvas/do-fetch-api-effect')

afterEach(() => {
  // @ts-expect-error
  doFetchApi.mockClear()
})

describe('useAccountDefaultGradingSchemeUpdateHook', () => {
  it('renders for course context without error', () => {
    const {result} = renderHook(() => useAccountDefaultGradingSchemeUpdate())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useAccountDefaultGradingSchemeUpdate())
    expect(result.error).toBeFalsy()
  })

  it('makes a POST request for account context to update a grading scheme', async () => {
    const {result} = renderHook(() => useAccountDefaultGradingSchemeUpdate())
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]

    // @ts-expect-error
    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: {title: 'Scheme 1', data},
    })
    const loadedGradingScheme = await result.current.updateAccountDefaultGradingScheme(
      accountId,
      '99',
    )
    // @ts-expect-error
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/accounts/${accountId}/grading_schemes/account_default`,
      method: 'PUT',
      body: {id: '99'},
    })

    expect(loadedGradingScheme).toEqual({title: 'Scheme 1', data})

    expect(result.current.updateAccountDefaultGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })
})
