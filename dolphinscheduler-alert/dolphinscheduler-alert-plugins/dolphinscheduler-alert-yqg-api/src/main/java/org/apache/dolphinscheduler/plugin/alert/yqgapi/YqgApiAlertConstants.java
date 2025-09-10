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

/**
 * Custom alert constants
 */
public final class YqgApiAlertConstants {

    private YqgApiAlertConstants() {
        throw new UnsupportedOperationException("This is a utility class and cannot be instantiated");
    }

    /**
     * External API URL
     */
    public static final String NAME_API_URL = "apiUrl";

    /**
     * Group ID
     */
    public static final String NAME_GROUP_ID = "groupId";

    /**
     * Alert Level
     */
    public static final String NAME_ALERT_LEVEL = "alertLevel";

    /**
     * Timeout
     */
    public static final String NAME_TIMEOUT = "timeout";

    /**
     * Default timeout
     */
    public static final int DEFAULT_TIMEOUT = 10;

    /**
     * Default API URL
     */
    public static final String DEFAULT_API_URL = "https://alert-api.yangqianguan.com/alertNotif/active";

    /**
     * Default group ID
     */
    public static final String DEFAULT_GROUP_ID = "90";

    /**
     * Default alert level
     */
    public static final String DEFAULT_ALERT_LEVEL = "WARN";

    /**
     * Alert status active
     */
    public static final String ALERT_STATUS_ACTIVE = "ACTIVE";

    /**
     * Previous process is still running title
     */
    public static final String TITLE_PREVIOUS_RUNNING = "Previous process is still running";

    /**
     * Process timeout warn title
     */
    public static final String TITLE_TIMEOUT_WARN = "Process Timeout Warn";

    /**
     * Dolphin scheduler process failed title
     */
    public static final String TITLE_PROCESS_FAILED = "Dolphin scheduler process failed";

    /**
     * Dolphin scheduler process timeout title
     */
    public static final String TITLE_PROCESS_TIMEOUT = "Dolphin scheduler process timeout";

    /**
     * Time threshold for previous running alert (30 seconds)
     */
    public static final long PREVIOUS_RUNNING_THRESHOLD = 30000L;
}
