/* testcase.vala
 *
 * Copyright (C) 2009 Julien Peeters
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *     Julien Peeters <contact@julienpeeters.fr>
 */

public abstract class Gee.TestCase : Object {

    private GLib.TestSuite suite;
    private TestAdaptor[] adaptors = new TestAdaptor[0];

    protected TestCase (string name) {
        this.suite = new GLib.TestSuite (name);
    }

    public void add_test (string name, owned TestMethod test) {
        var adaptor = new TestDefaultAdaptor (name, (owned)test, this);
        this.adaptors += adaptor;

        this.suite.add (new GLib.TestCase (adaptor.name,
                                           adaptor.set_up,
                                           adaptor.run,
                                           adaptor.tear_down ));
    }

    public void add_async_test (string name, owned AsyncTestMethod test, int timeout = 10000) {
        var adaptor = new TestAsyncAdaptor (name, (owned)test, this, timeout);
        this.adaptors += adaptor;

        this.suite.add (new GLib.TestCase (adaptor.name,
                                           adaptor.set_up,
                                           adaptor.run,
                                           adaptor.tear_down ));
    }

    public virtual void set_up () {
    }

    public virtual void tear_down () {
    }

    public GLib.TestSuite get_suite () {
        return (owned) this.suite;
    }
}

namespace Gee {
    public delegate void TestMethod ();
    public delegate void TestFinishedCallback ();
    public delegate void AsyncTestMethod (TestFinishedCallback cb);
}

private interface Gee.TestAdaptor : Object {
    public abstract void set_up (void* fixture);
    public abstract void run (void* fixture);
    public abstract void tear_down (void* fixture);
}

private class Gee.TestDefaultAdaptor : Object, TestAdaptor {
    [CCode (notify = false)]
    public string name { get; private set; }
    private TestMethod test;
    private TestCase test_case;

    public TestDefaultAdaptor (string name,
    owned TestMethod test,
    TestCase test_case) {
        this.name = name;
        this.test = (owned)test;
        this.test_case = test_case;
    }

    public void set_up (void* fixture) {
        this.test_case.set_up ();
    }

    public void run (void* fixture) {
        this.test ();
    }

    public void tear_down (void* fixture) {
        this.test_case.tear_down ();
    }
}

private class Gee.TestAsyncAdaptor : Object, TestAdaptor {
    [CCode (notify = false)]
    public string name { get; private set; }
    private AsyncTestMethod test;
    private TestCase test_case;
    private MainLoop main_loop;
    private int timeout;

    public TestAsyncAdaptor (string name,
    owned AsyncTestMethod test,
    TestCase test_case,
    int timeout) {
        this.name = name;
        this.test = (owned)test;
        this.test_case = test_case;
        this.timeout = timeout;
    }

    public void set_up (void* fixture) {
        this.test_case.set_up ();
        main_loop = new MainLoop ();
    }

    public void run (void* fixture) {
        this.test (finish);
        Timeout.add (timeout, finish_timeout);
        main_loop.run ();
    }

    public void finish () {
        Idle.add (() => { main_loop.quit (); return false; });
    }

    public bool finish_timeout () {
        Test.fail ();
        Test.message (@"Timeout of $(timeout)ms reached.");
        main_loop.quit ();
        return false;
    }

    public void tear_down (void* fixture) {
        this.test_case.tear_down ();
    }
}
