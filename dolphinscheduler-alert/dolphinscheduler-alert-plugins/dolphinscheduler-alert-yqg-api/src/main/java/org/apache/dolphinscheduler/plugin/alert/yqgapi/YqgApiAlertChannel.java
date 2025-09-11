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

import org.apache.dolphinscheduler.alert.api.AlertChannel;
import org.apache.dolphinscheduler.alert.api.AlertData;
import org.apache.dolphinscheduler.alert.api.AlertInfo;
import org.apache.dolphinscheduler.alert.api.AlertResult;

import java.util.Map;

import lombok.extern.slf4j.Slf4j;

/**
 * Custom alert channel for processing alerts with external API integration
 */
@Slf4j
public final class YqgApiAlertChannel implements AlertChannel {

    @Override
    public AlertResult process(AlertInfo alertInfo) {
        AlertData alertData = alertInfo.getAlertData();
        Map<String, String> paramsMap = alertInfo.getAlertParams();

        if (paramsMap == null) {
            log.warn("Alert parameters are null");
            return new AlertResult(false, "Custom alert params is null");
        }

        if (alertData == null) {
            log.warn("Alert data is null");
            return new AlertResult(false, "Alert data is null");
        }

        try {
            return YqgApiAlertSender.send(alertData, paramsMap);
        } catch (Exception e) {
            log.error("Failed to process custom alert: {}", e.getMessage(), e);
            return new AlertResult(false, "Custom alert processing failed: " + e.getMessage());
        }
    }

}
