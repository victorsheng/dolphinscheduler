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

import org.apache.dolphinscheduler.alert.api.AlertData;
import org.apache.dolphinscheduler.alert.api.AlertResult;
import org.apache.dolphinscheduler.common.utils.JSONUtils;

import org.apache.http.HttpStatus;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import lombok.extern.slf4j.Slf4j;

import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * Custom alert sender for processing alerts with external API integration
 */
@Slf4j
public final class YqgApiAlertSender {

    private YqgApiAlertSender() {
        throw new UnsupportedOperationException("This is a utility class and cannot be instantiated");
    }

    /**
     * Send alert with custom processing logic
     *
     * @param alertData  alert data
     * @param paramsMap  alert parameters
     * @return alert result
     */
    public static AlertResult send(AlertData alertData, Map<String, String> paramsMap) {
        AlertResult alertResult = new AlertResult();

        try {
            // Extract parameters
            String apiUrl = paramsMap.getOrDefault(YqgApiAlertConstants.NAME_API_URL,
                    YqgApiAlertConstants.DEFAULT_API_URL);
            String groupId = paramsMap.getOrDefault(YqgApiAlertConstants.NAME_GROUP_ID,
                    YqgApiAlertConstants.DEFAULT_GROUP_ID);
            String alertLevel = paramsMap.getOrDefault(YqgApiAlertConstants.NAME_ALERT_LEVEL,
                    YqgApiAlertConstants.DEFAULT_ALERT_LEVEL);

            log.info("Processing custom alert: title={}, groupId={}, level={}",
                    alertData.getTitle(), groupId, alertLevel);

            // Process alert with custom logic
            execAlert(alertData, groupId, alertLevel, apiUrl);

            alertResult.setSuccess(true);
            alertResult.setMessage("Custom alert processed successfully");

        } catch (Exception e) {
            log.error("Failed to process custom alert: {}", e.getMessage(), e);
            alertResult.setSuccess(false);
            alertResult.setMessage("Custom alert processing failed: " + e.getMessage());
        }

        return alertResult;
    }

    /**
     * Parse alert level and group ID from alert group name
     * Format: "alert-group-{level}-{groupId}"
     *
     * @param groupName alert group name
     * @return array with [level, groupId]
     */
    public static String[] parseGroupName(String groupName) {
        if (groupName == null || !groupName.contains("-")) {
            return new String[]{YqgApiAlertConstants.DEFAULT_ALERT_LEVEL,
                    YqgApiAlertConstants.DEFAULT_GROUP_ID};
        }

        String[] parts = groupName.split("-");
        if (parts.length >= 3) {
            return new String[]{parts[1], parts[2]};
        } else if (parts.length == 2) {
            return new String[]{parts[1], YqgApiAlertConstants.DEFAULT_GROUP_ID};
        } else {
            return new String[]{YqgApiAlertConstants.DEFAULT_ALERT_LEVEL,
                    YqgApiAlertConstants.DEFAULT_GROUP_ID};
        }
    }

    /**
     * Send alert SMS to external API
     *
     * @param groupId    group ID
     * @param level      alert level
     * @param title      alert title
     * @param info       alert content
     * @param apiUrl     external API URL
     */
    public static void alertSms(String groupId, String level, String title, String info, String apiUrl) {
        ObjectNode param = JSONUtils.createObjectNode();
        param.put("groupId", groupId);
        param.put("status", YqgApiAlertConstants.ALERT_STATUS_ACTIVE);
        param.put("level", level);
        param.put("title", title);
        param.put("content", info);

        try {
            String result = doPostJson(apiUrl, JSONUtils.toJsonString(param));
            log.info("Alert SMS sent successfully: groupId={}, level={}, title={} ,result={}", groupId, level, title,result);
        } catch (Exception e) {
            log.error("Failed to send alert SMS: {}", e.getMessage(), e);
        }
    }

    /**
     * Execute alert processing based on alert type
     *
     * @param alertData  alert data
     * @param groupId    group ID
     * @param alertLevel alert level
     * @param apiUrl     external API URL
     */
    public static void execAlert(AlertData alertData, String groupId, String alertLevel,
                                 String apiUrl) {
        if (alertData == null || alertData.getContent() == null) {
            log.warn("Alert data or content is null, skipping alert processing");
            return;
        }

        String title = alertData.getTitle();
        if (title == null) {
            log.warn("Alert title is null, skipping alert processing");
            return;
        }

        try {
            // if (YqgApiAlertConstants.TITLE_PREVIOUS_RUNNING.equals(title)) {
            // previousRunningAlert(alertData, groupId, alertLevel, alertDao, apiUrl);
            // } else if (YqgApiAlertConstants.TITLE_TIMEOUT_WARN.equals(title)) {
            // timeoutAlert(alertData, groupId, alertLevel, alertDao, apiUrl);
            // } else {
            failedAlert(alertData, groupId, alertLevel, apiUrl);
            // }
        } catch (Exception e) {
            log.error("Error processing alert: title={}, error={}", title, e.getMessage(), e);
        }
    }

    /**
     * Process failed alert
     */
    private static void failedAlert(AlertData alertData, String groupId, String alertLevel,
                                    String apiUrl) {
        try {
            // For now, we'll send the alert directly since the required DAO methods are not available
            // In a real implementation, you would need to implement these methods in AlertDao
            log.info("Processing failed alert: {}", alertData.getContent());
            alertSms(groupId, alertLevel.toUpperCase(),
                    YqgApiAlertConstants.TITLE_PROCESS_FAILED,
                    alertData.getContent(), apiUrl);
        } catch (Exception e) {
            log.error("Error processing failed alert: {}", e.getMessage(), e);
        }
    }

    /**
     * Send POST request with JSON body
     *
     * @param url  request URL
     * @param json JSON string
     * @return response string
     * @throws Exception if request fails
     */
    public static String doPostJson(String url, String json) throws Exception {
        return doPostJson(url, json, YqgApiAlertConstants.DEFAULT_TIMEOUT);
    }

    /**
     * Send POST request with JSON body and timeout
     *
     * @param url     request URL
     * @param json    JSON string
     * @param timeout timeout in seconds
     * @return response string
     * @throws Exception if request fails
     */
    public static String doPostJson(String url, String json, int timeout) throws Exception {
        log.info("Sending HTTP POST request to {}: {}", url, json);
        CloseableHttpClient httpClient = null;
        CloseableHttpResponse response = null;

        try {
            // Create HTTP client
            httpClient = HttpClients.createDefault();

            // Create POST request
            HttpPost httpPost = new HttpPost(url);

            // Set request config with timeout
            RequestConfig requestConfig = RequestConfig.custom()
                    .setConnectTimeout(timeout * 1000)
                    .setConnectionRequestTimeout(timeout * 1000)
                    .setSocketTimeout(timeout * 1000)
                    .build();
            httpPost.setConfig(requestConfig);

            // Set headers
            httpPost.setHeader("Content-Type", "application/json; charset=UTF-8");
            httpPost.setHeader("Accept", "application/json");

            // Set request body
            StringEntity entity = new StringEntity(json, ContentType.APPLICATION_JSON);
            httpPost.setEntity(entity);

            // Execute request
            response = httpClient.execute(httpPost);

            // Check response status
            int statusCode = response.getStatusLine().getStatusCode();
            if (statusCode != HttpStatus.SC_OK) {
                throw new RuntimeException("HTTP request failed with status code: " + statusCode);
            }

            // Get response body
            return EntityUtils.toString(response.getEntity(), StandardCharsets.UTF_8);

        } catch (IOException e) {
            log.error("Failed to send HTTP POST request to {}: {}", url, e.getMessage(), e);
            throw new Exception("HTTP request failed: " + e.getMessage(), e);
        } finally {
            // Close resources
            if (response != null) {
                try {
                    response.close();
                } catch (IOException e) {
                    log.warn("Failed to close HTTP response: {}", e.getMessage());
                }
            }
            if (httpClient != null) {
                try {
                    httpClient.close();
                } catch (IOException e) {
                    log.warn("Failed to close HTTP client: {}", e.getMessage());
                }
            }
        }
    }
}
