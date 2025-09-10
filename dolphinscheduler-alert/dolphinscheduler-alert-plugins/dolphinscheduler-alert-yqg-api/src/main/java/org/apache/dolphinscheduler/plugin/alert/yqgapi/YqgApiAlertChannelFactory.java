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
import org.apache.dolphinscheduler.alert.api.AlertChannelFactory;
import org.apache.dolphinscheduler.spi.params.base.PluginParams;
import org.apache.dolphinscheduler.spi.params.input.InputParam;

import java.util.Arrays;
import java.util.List;

/**
 * Custom alert channel factory
 */
public final class YqgApiAlertChannelFactory implements AlertChannelFactory {

    @Override
    public String name() {
        return "custom";
    }

    @Override
    public AlertChannel create() {
        return new YqgApiAlertChannel();
    }

    @Override
    public List<PluginParams> params() {
        return Arrays.asList(
                InputParam.newBuilder(YqgApiAlertConstants.NAME_API_URL, "API URL")
                        .setPlaceholder("External alert API URL")
                        .build(),
                InputParam.newBuilder(YqgApiAlertConstants.NAME_GROUP_ID, "Group ID")
                        .setPlaceholder("Alert group ID")
                        .build(),
                InputParam.newBuilder(YqgApiAlertConstants.NAME_ALERT_LEVEL, "Alert Level")
                        .setPlaceholder("Alert level (WARN, ERROR, INFO)")
                        .build(),
                InputParam.newBuilder(YqgApiAlertConstants.NAME_TIMEOUT, "Timeout")
                        .setPlaceholder("Request timeout in seconds")
                        .build());
    }
}
