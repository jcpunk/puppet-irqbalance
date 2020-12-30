require 'spec_helper'

describe 'irqbalance' do

  context 'without parameters' do
    it { should compile.with_all_deps }
    it {
      is_expected.to contain_package('irqbalance').
        with_ensure('installed').
        that_notifies('Service[irqbalance.service]')
    }

    it {
      is_expected.to contain_service('irqbalance.service').
        with_ensure('running').
        with_enable(true)
    }

    it {
      is_expected.to contain_file('/usr/lib/systemd/system/irqbalance.service').
        with_ensure('file').
        with_owner('root').
        with_group('root').
        with_mode('0644')
    }

    it {
      is_expected.to contain_file('/usr/lib/systemd/system/irqbalance.service.d').
        with_ensure('directory').
        with_owner('root').
        with_group('root').
        with_mode('0755')
    }

    it {
      is_expected.to contain_file('/usr/lib/systemd/system/irqbalance.service.d/puppet.conf').
        with_ensure('file').
        with_owner('root').
        with_group('root').
        with_mode('0644').
        that_notifies('Service[irqbalance.service]').
        that_notifies('Class[systemd::systemctl::daemon_reload]')
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/irqbalance').
        with_ensure('file').
        with_owner('root').
        with_group('root').
        with_mode('0644').
        that_notifies('Service[irqbalance.service]')
    }

  end

end
