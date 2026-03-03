<?php
declare(strict_types=1);
require_once(__DIR__ . "/vendor/autoload.php");
/**
 * Elasticlogs Plugin for Roundcube
 *
 * @author Sérgio Carvalho <daf@sooma.com>
 *
 * Copyright (C) Sooma.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */
class elasticlogs extends rcube_plugin
{
    public $rc;
    public $config = null;

    public function init()
    {
        $this->rc = rcmail::get_instance();
        $this->load_config();
        $this->add_texts('localization/');
    }
}