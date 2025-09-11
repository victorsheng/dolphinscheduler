-- =============================================
-- YQG API 告警插件数据库插入SQL
-- 生成时间: 2025-01-30
-- 插件名称: yqgapi
-- =============================================

-- 1. 插入插件定义到 t_ds_plugin_define 表
INSERT INTO `t_ds_plugin_define` (
    `plugin_name`, 
    `plugin_type`, 
    `plugin_params`, 
    `create_time`, 
    `update_time`
) VALUES (
    'yqgapi',
    'alert',
    '[{"props":{"placeholder":"External alert API URL","size":"small"},"field":"apiUrl","name":"API URL","type":"input","title":"API URL","validate":[{"required":false,"type":"string","trigger":"blur"}]},{"props":{"placeholder":"Alert group ID","size":"small"},"field":"groupId","name":"Group ID","type":"input","title":"Group ID","validate":[{"required":false,"type":"string","trigger":"blur"}]},{"props":{"placeholder":"Alert level (WARN, ERROR, INFO)","size":"small"},"field":"alertLevel","name":"Alert Level","type":"input","title":"Alert Level","validate":[{"required":false,"type":"string","trigger":"blur"}]},{"props":{},"field":"timeout","name":"Timeout","type":"input-number","title":"Timeout","value":10,"validate":[{"required":false,"type":"number","trigger":"blur"}]}]',
    NOW(),
    NOW()
);

-- 2. 插入告警插件实例到 t_ds_alert_plugin_instance 表
-- 注意: plugin_define_id 需要根据上面插入的插件定义ID来设置
-- 这里假设插件定义ID为1，实际使用时需要查询获取正确的ID

INSERT INTO `t_ds_alert_plugin_instance` (
    `plugin_define_id`,
    `instance_name`,
    `plugin_instance_params`,
    `instance_type`,
    `warning_type`,
    `create_time`,
    `update_time`
) VALUES (
    (SELECT id FROM `t_ds_plugin_define` WHERE `plugin_name` = 'yqgapi' AND `plugin_type` = 'alert'),
    'YQG API Alert Instance',
    '{"apiUrl":"https://alert-api.yangqianguan.com/alertNotif/active","groupId":"398","alertLevel":"WARN","timeout":10}',
    0,
    3,
    NOW(),
    NOW()
);

-- =============================================
-- 查询验证SQL
-- =============================================

-- 查询插件定义
SELECT * FROM `t_ds_plugin_define` WHERE `plugin_name` = 'yqgapi';

-- 查询告警插件实例
SELECT * FROM `t_ds_alert_plugin_instance` WHERE `instance_name` = 'YQG API Alert Instance';

-- =============================================
-- 删除SQL (如果需要清理)
-- =============================================

-- 删除告警插件实例
-- DELETE FROM `t_ds_alert_plugin_instance` WHERE `instance_name` = 'YQG API Alert Instance';

-- 删除插件定义
-- DELETE FROM `t_ds_plugin_define` WHERE `plugin_name` = 'yqgapi' AND `plugin_type` = 'alert';
