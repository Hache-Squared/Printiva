using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioReportes
    {
        Task<ReporteConsumoViewModel> ConsumoInventario(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? pedidoId,
            int? inventarioId,
            int? usuarioFiltroId,
            int? productoId,
            int? recetaId
        );

        Task<ReporteProduccionViewModel> ProduccionDashboard(int usuarioId);

        Task<ReporteCosteoViewModel> Costeo(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? pedidoId
        );

        Task<ReportePedido360ViewModel> Pedido360(int usuarioId, int pedidoId);
    }
    public class RepositorioReportes : IRepositorioReportes
    {
        private readonly string connectionString;

        public RepositorioReportes(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<ReporteConsumoViewModel> ConsumoInventario(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? pedidoId,
            int? inventarioId,
            int? usuarioFiltroId,
            int? productoId,
            int? recetaId
        )
        {
            var vm = new ReporteConsumoViewModel
            {
                Desde = (desde ?? DateTime.Today.AddDays(-7)).Date,
                Hasta = (hasta ?? DateTime.Today).Date,
                PedidoId = pedidoId,
                InventarioId = inventarioId,
                UsuarioId = usuarioFiltroId,
                ProductoId = productoId,
                RecetaId = recetaId
            };

            using var connection = new SqlConnection(connectionString);

            // 1) Resumen: regresa 2 resultsets (Totales + TopInsumos)
            using (var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesConsumoInventarioResumen",
                new
                {
                    FechaDesde = vm.Desde,
                    FechaHasta = vm.Hasta,
                    PedidoId = (int?)vm.PedidoId,
                    InventarioId = (int?)vm.InventarioId,
                    UsuarioId = (int?)vm.UsuarioId,
                    ProductoId = (int?)vm.ProductoId,
                    RecetaId = (int?)vm.RecetaId
                },
                commandType: CommandType.StoredProcedure
            ))
            {
                vm.Totales = (await multi.ReadAsync<ReporteConsumoTotales>()).FirstOrDefault()
                             ?? new ReporteConsumoTotales();

                vm.TopInsumos = (await multi.ReadAsync<ReporteConsumoTopInsumo>()).ToList();
            }

            // 2) Detalle
            var rows = await connection.QueryAsync<ReporteConsumoRow>(
                "dbo.procReportesConsumoInventarioDetalle",
                new
                {
                    FechaDesde = vm.Desde,
                    FechaHasta = vm.Hasta,
                    PedidoId = (int?)vm.PedidoId,
                    InventarioId = (int?)vm.InventarioId,
                    UsuarioId = (int?)vm.UsuarioId,
                    ProductoId = (int?)vm.ProductoId,
                    RecetaId = (int?)vm.RecetaId
                },
                commandType: CommandType.StoredProcedure
            );

            vm.Rows = rows.ToList();
            return vm;
        }

        public async Task<ReporteProduccionViewModel> ProduccionDashboard(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesProduccionDashboard",
                new { loginId = usuarioId },
                commandType: CommandType.StoredProcedure
            );

            var vm = new ReporteProduccionViewModel
            {
                ItemsPorEstatus = (await multi.ReadAsync<ReporteProduccionEstatusRow>()).ToList(),
                PedidosPorEstatus = (await multi.ReadAsync<ReportePedidoEstatusRow>()).ToList(),
                Wip = (await multi.ReadAsync<ReporteProduccionWipRow>()).FirstOrDefault() ?? new ReporteProduccionWipRow()
            };

            return vm;
        }

        public async Task<ReporteCosteoViewModel> Costeo(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? pedidoId
        )
        {
            var vm = new ReporteCosteoViewModel
            {
                Desde = (desde ?? DateTime.Today.AddDays(-30)).Date,
                Hasta = (hasta ?? DateTime.Today).Date,
                PedidoId = pedidoId
            };

            using var connection = new SqlConnection(connectionString);

            // Resumen por pedidos
            var pedidos = await connection.QueryAsync<ReporteCosteoPedidoRow>(
                "dbo.procReportesCosteoPedidos",
                new
                {
                    FechaDesde = vm.Desde,
                    FechaHasta = vm.Hasta,
                    PedidoId = (int?)vm.PedidoId,
                    loginId = usuarioId
                },
                commandType: CommandType.StoredProcedure
            );

            vm.Pedidos = pedidos.ToList();

            // Detalle por pedido (si se selecciona uno)
            if (vm.PedidoId.HasValue)
            {
                var detalle = await connection.QueryAsync<ReporteCosteoDetalleRow>(
                    "dbo.procReportesCosteoPedidoDetalle",
                    new
                    {
                        PedidoId = vm.PedidoId.Value,
                        loginId = usuarioId
                    },
                    commandType: CommandType.StoredProcedure
                );

                vm.Detalle = detalle.ToList();
            }

            return vm;
        }

        public async Task<ReportePedido360ViewModel> Pedido360(int usuarioId, int pedidoId)
        {
            var vm = new ReportePedido360ViewModel { PedidoId = pedidoId };

            using var connection = new SqlConnection(connectionString);

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesPedido360",
                new { pedidoId = pedidoId, loginId = usuarioId },
                commandType: CommandType.StoredProcedure
            );

            vm.Header = (await multi.ReadAsync<ReportePedido360Header>()).FirstOrDefault();

            if (vm.Header is null)
            {
                vm.Mensaje = "No se encontró el pedido o no tienes acceso.";
                return vm;
            }

            vm.Items = (await multi.ReadAsync<ReportePedido360ItemRow>()).ToList();
            vm.Cotizacion = (await multi.ReadAsync<ReportePedido360CotizacionRow>()).ToList();
            vm.Pagos = (await multi.ReadAsync<ReportePedido360PagoRow>()).ToList();
            vm.Produccion = (await multi.ReadAsync<ReportePedido360ProduccionRow>()).ToList();
            vm.Consumo = (await multi.ReadAsync<ReportePedido360ConsumoRow>()).ToList();
            vm.Historia = (await multi.ReadAsync<ReportePedido360HistoriaRow>()).ToList();

            return vm;
        }

    }
}
