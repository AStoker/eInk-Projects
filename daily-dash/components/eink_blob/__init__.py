"""Panel-ready image blob fetcher for the eInk Daily Dash.

Wraps http_request so the display lambda can pull a pre-dithered, pre-sized
two-plane image and blit it a row at a time. See IMAGE-PIPELINE.md.
"""

import esphome.codegen as cg
import esphome.config_validation as cv
from esphome.components import display, http_request
from esphome.const import CONF_ID, CONF_TIMEOUT

CODEOWNERS = ["@AStoker"]
DEPENDENCIES = ["http_request", "display"]

eink_blob_ns = cg.esphome_ns.namespace("eink_blob")
EinkBlob = eink_blob_ns.class_("EinkBlob", cg.Component)

CONF_HTTP_REQUEST_ID = "http_request_id"
CONF_PROBE_TIMEOUT = "probe_timeout"

CONFIG_SCHEMA = cv.Schema(
    {
        cv.GenerateID(): cv.declare_id(EinkBlob),
        cv.GenerateID(CONF_HTTP_REQUEST_ID): cv.use_id(
            http_request.HttpRequestComponent
        ),
        cv.Optional(CONF_TIMEOUT, default="15s"): cv.positive_time_period_milliseconds,
        cv.Optional(
            CONF_PROBE_TIMEOUT, default="4s"
        ): cv.positive_time_period_milliseconds,
    }
).extend(cv.COMPONENT_SCHEMA)


async def to_code(config):
    var = cg.new_Pvariable(config[CONF_ID])
    await cg.register_component(var, config)

    parent = await cg.get_variable(config[CONF_HTTP_REQUEST_ID])
    cg.add(var.set_parent(parent))
    cg.add(var.set_timeout_ms(config[CONF_TIMEOUT]))
    cg.add(var.set_probe_timeout_ms(config[CONF_PROBE_TIMEOUT]))
