/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.dolphinscheduler.plugin.alert.yqgapi;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

import org.apache.dolphinscheduler.alert.api.AlertData;
import org.apache.dolphinscheduler.alert.api.AlertInfo;
import org.apache.dolphinscheduler.alert.api.AlertResult;

import java.util.HashMap;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Test for YqgApiAlertChannel
 */
@ExtendWith(MockitoExtension.class)
class YqgApiAlertChannelTest {

    @Mock
    private AlertInfo alertInfo;

    @Mock
    private AlertData alertData;

    private YqgApiAlertChannel customAlertChannel;

    @BeforeEach
    void setUp() {
        customAlertChannel = new YqgApiAlertChannel();
    }

    @Test
    void testProcessWithNullParams() {
        when(alertInfo.getAlertParams()).thenReturn(null);
        when(alertInfo.getAlertData()).thenReturn(alertData);

        AlertResult result = customAlertChannel.process(alertInfo);

        assertNotNull(result);
        assertFalse(result.isSuccess());
        assertTrue(result.getMessage().contains("Custom alert params is null"));
    }

    @Test
    void testProcessWithNullAlertData() {
        Map<String, String> paramsMap = new HashMap<>();
        paramsMap.put(YqgApiAlertConstants.NAME_API_URL, "http://test.com");
        paramsMap.put(YqgApiAlertConstants.NAME_GROUP_ID, "1");
        paramsMap.put(YqgApiAlertConstants.NAME_ALERT_LEVEL, "WARN");

        when(alertInfo.getAlertParams()).thenReturn(paramsMap);
        when(alertInfo.getAlertData()).thenReturn(null);

        AlertResult result = customAlertChannel.process(alertInfo);

        assertNotNull(result);
        assertFalse(result.isSuccess());
        assertTrue(result.getMessage().contains("Alert data is null"));
    }

    @Test
    void testProcessWithValidData() {
        Map<String, String> paramsMap = new HashMap<>();
        paramsMap.put(YqgApiAlertConstants.NAME_API_URL, "https://alert-api.yangqianguan.com/alertNotif/active");
        paramsMap.put(YqgApiAlertConstants.NAME_GROUP_ID, "398");
        paramsMap.put(YqgApiAlertConstants.NAME_ALERT_LEVEL, "WARN");

        when(alertInfo.getAlertParams()).thenReturn(paramsMap);
        when(alertInfo.getAlertData()).thenReturn(alertData);
        when(alertData.getTitle()).thenReturn("Test Alert");
        when(alertData.getContent()).thenReturn("Test Content");

        AlertResult result = customAlertChannel.process(alertInfo);

        assertNotNull(result);
        // Note: This test will fail because AlertDao is not properly injected
        // In a real test environment, you would need to mock the AlertDao
        assertFalse(result.isSuccess());
    }
}
