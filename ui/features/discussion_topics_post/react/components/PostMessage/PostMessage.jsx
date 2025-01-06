/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {DiscussionEdit} from '../DiscussionEdit/DiscussionEdit'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState} from 'react'
import {
  getDisplayName,
  responsiveQuerySizes,
  getTranslation,
  translationSeparator,
} from '../../utils'
import {DiscussionManagerUtilityContext, SearchContext} from '../../utils/constants'
import {SearchSpan} from '../SearchSpan/SearchSpan'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import theme from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('discussion_posts')

export function PostMessage({...props}) {
  const {searchTerm} = useContext(SearchContext)

  useEffect(() => {
    if (ENV.SEQUENCE !== undefined && props.isTopic) {
      import('@canvas/modules/jquery/prerequisites_lookup').then(() => {
        INST.lookupPrerequisites()
      })
    }
  }, [props.isTopic])

  let heading = 'h2'

  if (props.discussionEntry) {
    const depth = Math.min(props.discussionEntry.depth + 2, 5)
    heading = 'h' + depth.toString()
  }

  const {translateTargetLanguage} = useContext(DiscussionManagerUtilityContext)
  const [translatedTitle, setTranslatedTitle] = useState(null)
  const [translatedMessage, setTranslatedMessage] = useState(null)
  const [isTranslating, setIsTranslating] = useState(false)

  // Shouldn't fire if not feature flagged.
  // TODO Create a custom hook for translation logic.
  useEffect(() => {
    if (translateTargetLanguage == null) {
      setTranslatedTitle(null)
      setTranslatedMessage(null)
      return
    }

    const translationAttempts = [
      getTranslation(props.title, translateTargetLanguage),
      getTranslation(props.message, translateTargetLanguage),
    ]

    // Begin translating, clear spinner when done.
    setIsTranslating(true)
    Promise.all(translationAttempts)
      .then(translations => {
        setTranslatedTitle(translations[0])
        setTranslatedMessage(translations[1])
      })
      .catch(() => {
        setTranslatedTitle(null)
        setTranslatedMessage(null)
      })
      .finally(() => setIsTranslating(false))
  }, [translateTargetLanguage, props.title, props.message])

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          titleMargin: 'small 0',
          titleDisplay: 'block',
          titleTextSize: 'large',
          titleTextWeight: 'bold',
          messageLeftPadding: undefined,
          isMobile: true,
        },
        desktop: {
          titleMargin: '0',
          titleDisplay: 'inline',
          titleTextSize: props.threadMode ? 'medium' : 'x-large',
          titleTextWeight: props.threadMode ? 'bold' : 'normal',
          messageLeftPadding:
            props.discussionEntry && props.discussionEntry.depth === 1 && !props.threadMode
              ? theme.spacing.xxSmall
              : undefined,
          isMobile: false,
        },
      }}
      render={responsiveProps => (
        <View>
          {props.title ? (
            <View margin={responsiveProps.titleMargin} display={responsiveProps.titleDisplay}>
              <Text size={responsiveProps.titleTextSize} data-testid="message_title" weight="bold">
                {translatedTitle ? (
                  <>
                    <AccessibleContent
                      alt={I18n.t('Discussion Topic: %{title}', {title: props.title})}
                    >
                      {props.title}
                    </AccessibleContent>
                    <AccessibleContent alt={translationSeparator}>
                      {translationSeparator}
                    </AccessibleContent>
                    <AccessibleContent alt={translatedTitle} data-testid="post-title-translated">
                      {translateTargetLanguage ? (
                        <span lang={translateTargetLanguage}>{translatedTitle}</span>
                      ) : (
                        translatedTitle
                      )}
                    </AccessibleContent>
                  </>
                ) : (
                  <AccessibleContent
                    alt={I18n.t('Discussion Topic: %{title}', {title: props.title})}
                  >
                    {props.title}
                  </AccessibleContent>
                )}
              </Text>
            </View>
          ) : (
            <View as={heading} margin={responsiveProps.titleMargin}>
              <Text size={responsiveProps.titleTextSize} weight={responsiveProps.titleTextWeight}>
                <AccessibleContent
                  alt={I18n.t('Reply from %{author}', {
                    author: getDisplayName(props.discussionEntry),
                  })}
                />
              </Text>
            </View>
          )}
          {isTranslating && (
            <Flex justifyItems="start">
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Translating')} size="x-small" />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">
                <Text>{I18n.t('Translating Text')}</Text>
              </Flex.Item>
            </Flex>
          )}
          {props.isEditing ? (
            <View display="inline-block" margin="small none none none" width="100%">
              <DiscussionEdit
                rceIdentifier={`${props.discussionEntry._id}-edit`}
                discussionAnonymousState={props.discussionAnonymousState}
                canReplyAnonymously={props.canReplyAnonymously}
                onCancel={props.onCancel}
                value={props.message}
                attachment={props.attachment}
                quotedEntry={props.discussionEntry.quotedEntry}
                onSubmit={props.onSave}
                isEdit={true}
                isAnnouncement={props.discussionTopic?.isAnnouncement}
              />
            </View>
          ) : (
            <>
              <div
                className={'userMessage' + (responsiveProps.isMobile ? ' mobile' : '')}
                style={{
                  marginLeft: responsiveProps.messageLeftPadding,
                }}
              >
                <SearchSpan
                  isSplitView={props.isSplitView}
                  searchTerm={searchTerm}
                  text={props.message}
                  isAnnouncement={props.discussionTopic?.isAnnouncement}
                  isTopic={props.isTopic}
                  resourceId={
                    props.isTopic ? props.discussionTopic?._id : props.discussionEntry?._id
                  }
                />
                {translatedMessage && (
                  <>
                    <AccessibleContent alt={translationSeparator}>
                      {translationSeparator}
                    </AccessibleContent>
                    <SearchSpan
                      lang={translateTargetLanguage}
                      isSplitView={props.isSplitView}
                      searchTerm={searchTerm}
                      text={translatedMessage}
                      isAnnouncement={props.discussionTopic?.isAnnouncement}
                      isTopic={props.isTopic}
                      resourceId={
                        props.isTopic ? props.discussionTopic?._id : props.discussionEntry?._id
                      }
                      testId="post-message-translated"
                    />
                  </>
                )}
              </div>
              <View display="block">{props.children}</View>
            </>
          )}
        </View>
      )}
    />
  )
}

PostMessage.propTypes = {
  /**
   * Object containing the discussion entry information
   */
  discussionEntry: PropTypes.object,
  /**
   * Children to be directly rendered below the PostMessage
   */
  children: PropTypes.node,
  /**
   * Display text for the post's title. Only pass this in if it's a DiscussionTopic
   */
  title: PropTypes.string,
  /**
   * Display text for the post's message
   */
  message: PropTypes.string.isRequired,
  /*
   * Display attachment for the post's message
   */
  attachment: PropTypes.object,
  /**
   * Determines if the editor should be displayed
   */
  isEditing: PropTypes.bool,
  /**
   * Callback for when Editor Save button is pressed
   */
  onSave: PropTypes.func,
  /**
   * Callback for when Editor Cancel button is pressed
   */
  onCancel: PropTypes.func,
  isSplitView: PropTypes.bool,
  discussionAnonymousState: PropTypes.string,
  canReplyAnonymously: PropTypes.bool,
  threadMode: PropTypes.bool,
  isTopic: PropTypes.bool,
  discussionTopic: PropTypes.object,
}

PostMessage.defaultProps = {
  isSplitView: false,
}

export default PostMessage
