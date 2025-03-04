/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import useFetchApi from '@canvas/use-fetch-api-hook'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {FAKE_FILES, FAKE_FOLDERS, FAKE_FOLDERS_AND_FILES} from '../../../../../fixtures/fakeData'
import MoveModal from '../MoveModal'
import {FileManagementContext} from '../../../Contexts'

jest.mock('@canvas/use-fetch-api-hook')
jest.mock('@canvas/do-fetch-api-effect')

const defaultProps = {
  open: true,
  onDismiss: jest.fn(),
  items: FAKE_FOLDERS_AND_FILES,
}

const renderComponent = (props: any = {}) =>
  render(
    <FileManagementContext.Provider
      value={{
        folderId: '1',
        showingAllContexts: false,
        rootFolder: FAKE_FOLDERS[0],
        contextType: 'course',
        contextId: '1',
        fileIndexMenuTools: [],
      }}
    >
      <MoveModal {...defaultProps} {...props} />
    </FileManagementContext.Provider>,
  )

describe('MoveModal', () => {
  let flashElements: any

  beforeEach(() => {
    flashElements = document.createElement('div')
    flashElements.setAttribute('id', 'flash_screenreader_holder')
    flashElements.setAttribute('role', 'alert')
    document.body.appendChild(flashElements)
  })

  afterEach(() => {
    document.body.removeChild(flashElements)
    flashElements = undefined
  })

  it('renders header', async () => {
    renderComponent()
    expect(await screen.findByText('Move To...')).toBeInTheDocument()
  })

  describe('renders body', () => {
    describe('with preview', () => {
      it('for a files and folders', async () => {
        renderComponent()
        expect(
          await screen.findByText(`Selected Items (${FAKE_FOLDERS_AND_FILES.length})`),
        ).toBeInTheDocument()
      })

      it('for a file', async () => {
        renderComponent({items: [FAKE_FILES[0]]})
        expect(await screen.findByText(FAKE_FILES[0].display_name)).toBeInTheDocument()
      })

      it('for a folder', async () => {
        renderComponent({items: [FAKE_FOLDERS[0]]})
        const names = await screen.findAllByText(FAKE_FOLDERS[0].name)
        // the folder name and the tree
        expect(names).toHaveLength(2)
      })
    })

    describe('with text', () => {
      it('for a files and folders', async () => {
        renderComponent()
        expect(
          await screen.findByText('Where would you like to move these items?'),
        ).toBeInTheDocument()
      })

      it('for a file', async () => {
        renderComponent({items: [FAKE_FILES[0]]})
        expect(
          await screen.findByText('Where would you like to move this file?'),
        ).toBeInTheDocument()
      })

      it('for a folder', async () => {
        renderComponent({items: [FAKE_FOLDERS[0]]})
        expect(
          await screen.findByText('Where would you like to move this folder?'),
        ).toBeInTheDocument()
      })
    })
  })

  it('renders footer', async () => {
    renderComponent()
    expect(await screen.findByTestId('move-cancel-button')).toBeInTheDocument()
    expect(await screen.findByTestId('move-move-button')).toBeInTheDocument()
  })

  it('shows an error when there is not a selected folder', async () => {
    ;(useFetchApi as jest.Mock).mockImplementationOnce(({loading, success}) => {
      loading(false)
      success([FAKE_FOLDERS[1]])
    })
    renderComponent()
    await userEvent.click(await screen.findByTestId('move-move-button'))
    expect(await screen.findByText('A target folder should be selected.')).toBeInTheDocument()
  })

  it('performs fetch request', async () => {
    const rootFolder = FAKE_FOLDERS[1]
    const childFolder = FAKE_FOLDERS[2]
    ;(useFetchApi as jest.Mock).mockImplementationOnce(({loading, success}) => {
      loading(false)
      success([childFolder])
    })
    // Fetch inner folders request
    ;(doFetchApi as jest.Mock).mockResolvedValue([])
    // Fetch folder data
    ;(doFetchApi as jest.Mock).mockResolvedValue({
      json: [],
    })

    renderComponent()
    await userEvent.click(await screen.findByText(childFolder.name))
    await userEvent.click(await screen.findByTestId('move-move-button'))

    await waitFor(() => {
      expect(screen.getAllByText(/success/i)[0]).toBeInTheDocument()

      expect(doFetchApi).toHaveBeenCalledWith({
        path: `/api/v1/folders/${rootFolder.id}`,
        method: 'PUT',
        body: expect.objectContaining({
          parent_folder_id: childFolder.id,
        }),
      })
    })
  })
})
