require 'spec_helper'

describe 'irqbalance' do
  context 'without parameters' do
    let(:facts) do
      {
        'path' => '/bin:/usr/bin',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_package('irqbalance')
        .with_ensure('installed')
        .that_notifies('Service[irqbalance.service]')
    }

    it {
      is_expected.to contain_service('irqbalance.service')
        .with_ensure('running')
        .with_enable(true)
    }

    it {
      is_expected.to contain_file('/usr/lib/systemd/system/irqbalance.service')
        .with_ensure('file')
        .with_owner('root')
        .with_group('root')
        .with_mode('0644')
    }

    it {
      is_expected.to contain_file('/usr/lib/systemd/system/irqbalance.service.d')
        .with_ensure('directory')
        .with_owner('root')
        .with_group('root')
        .with_mode('0755')
    }

    it {
      is_expected.to contain_file('/usr/lib/systemd/system/irqbalance.service.d/puppet.conf')
        .with_ensure('file')
        .with_owner('root')
        .with_group('root')
        .with_mode('0644')
        .that_notifies('Service[irqbalance.service]')
        .that_notifies('Class[systemd::systemctl::daemon_reload]')
        .with_content(%r{\[Service\]})
        .with_content(%r{Type=simple})
        .with_content(%r{EnvironmentFile=\/etc\/sysconfig\/irqbalance})
        .with_content(%r{ExecStart=\/usr\/sbin\/irqbalance --foreground \$IRQBALANCE_ARGS})
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/irqbalance')
        .with_ensure('file')
        .with_owner('root')
        .with_group('root')
        .with_mode('0644')
        .that_notifies('Service[irqbalance.service]')
        .with_content(%r{#IRQBALANCE_ONESHOT="no"})
        .with_content(%r{#IRQBALANCE_BANNED_CPUS=""})
    }
  end
  context 'when given values for params used in /etc/sysconfig/irqbalance' do
    let(:facts) do
      {
        'path' => '/bin:/usr/bin',
      }
    end
    let(:params) do
      {
        'oneshot'      => true,
        'hintpolicy'   => 'exact',
        'powerthresh'  => 389,
        'ban_irq'      => [3, 7],
        'ban_cpu'      => ['3A'],
        'deepestcache' => 3,
        'policyscript' => '/usr/bin/foo.sh',
        'extra_args'   => '--beep --boop',
      }
    end

    it {
      is_expected.to contain_file('/etc/sysconfig/irqbalance')
        .with_content(%r{^IRQBALANCE_ONESHOT="yes"$})
        .with_content(%r{^HINTPOLICY='--hintpolicy=exact'$})
        .with_content(%r{^POWERTHRESH='--powerthresh=389'$})
        .with_content(%r{^BANIRQ='--banirq=3 --banirq=7'$})
        .with_content(%r{^IRQBALANCE_BANNED_CPUS="3A"$})
        .with_content(%r{^DEEPESTCACHE='--deepestcache=3'$})
        .with_content(%r{^POLICYSCRIPT='--policyscript=\/usr\/bin\/foo.sh'$})
        .with_content(%r{^EXTRA_ARGS='--beep --boop'$})
    }
  end
  context 'when given values for params used in /usr/lib/systemd/system/irqbalance.service.d/puppet.conf' do
    let(:facts) do
      {
        'path' => '/bin:/usr/bin',
      }
    end
    let(:params) do
      {
        'oneshot' => true,
      }
    end

    it {
      is_expected.to contain_file('/usr/lib/systemd/system/irqbalance.service.d/puppet.conf')
        .with_content(%r{^Type=oneshot$})
        .with_content(%r{^RemainAfterExit=yes$})
    }
  end
end
