<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    public function createApplication()
    {
        $app = parent::createApplication();
        if (config('database.default') !== 'mysql' || config('database.connections.mysql.database') !== 'puntokampus_pruebas') {
            throw new \RuntimeException('Las pruebas solo se permiten en MySQL / puntokampus_pruebas.');
        }

        return $app;
    }
}
