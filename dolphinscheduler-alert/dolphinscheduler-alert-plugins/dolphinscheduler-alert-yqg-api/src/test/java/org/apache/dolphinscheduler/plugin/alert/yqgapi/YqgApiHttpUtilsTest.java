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

import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

/**
 * Test for YqgApiAlertSender
 */
class YqgApiHttpUtilsTest {

    @Test
    void testDoPostJsonWithInvalidUrl() {
        String invalidUrl = "invalid-url";
        String json = "{\"test\": \"data\"}";

        assertThrows(Exception.class, () -> {
            YqgApiAlertSender.doPostJson(invalidUrl, json);
        });
    }

    @Test
    void testDoPostJsonWithNullUrl() {
        String json = "{\"test\": \"data\"}";

        assertThrows(Exception.class, () -> {
            YqgApiAlertSender.doPostJson(null, json);
        });
    }

    @Test
    void testDoPostJsonWithNullJson() {
        String url = "http://httpbin.org/post";

        assertThrows(Exception.class, () -> {
            YqgApiAlertSender.doPostJson(url, null);
        });
    }

    // Note: Tests for successful HTTP requests would require a mock HTTP server
    // or a test endpoint that can be controlled. For now, we only test error cases.
}
