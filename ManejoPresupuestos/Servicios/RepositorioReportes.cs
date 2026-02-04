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

        Task<ReportePedidosOperativosViewModel> PedidosOperativos(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? pedidoEstatusId,
            int? clienteId,
            bool? soloAtrasados,
            int? produccionEstatusId,
            string? canal
        );


        Task<ReporteCxcViewModel> CxcAging(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? pedidoId,
            bool soloVencidos,
            int? bucketId,
            string? metodo,
            decimal? minSaldo
        );

        Task<ReporteCotizacionesSeguimientoViewModel> CotizacionesSeguimiento(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? cotizacionEstatusId,
            bool soloConvertidas,
            bool soloUltimaPorPedido,
            decimal? minMonto,
            string? q
        );

        Task<ReporteProduccionWipViewModel> GetProduccionWipDashboardAsync(
            int loginId,
            ReporteProduccionWipViewModel vm
        );

        Task<ReporteProduccionWipViewModel> ProduccionWipDashboard(
            int loginId,
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? pedidoId,
            int? estatusId,
            int? impresoraId,
            bool soloWip,
            bool soloAtrasados,
            bool sinImpresora,
            int? minDiasCola,
            string? q
        );
        Task<ReporteProduccionUtilizacionViewModel> ProduccionUtilizacionImpresoras(
            int loginId,
            DateTime? desde,
            DateTime? hasta,
            int? impresoraId,
            bool incluirEnCurso,
            bool incluirSinImpresora,
            string? q
        );

        Task<ReporteInventarioConsumoMejoradoViewModel> InventarioConsumoMejorado(
            int loginId,
            DateTime? desde,
            DateTime? hasta,
            int? pedidoId,
            int? productoId,
            int? recetaId,
            int? inventarioId,
            string periodo,
            int topN,
            string? q
        );

        Task<ReporteComprasHistoricoVm> ComprasHistorico(
            int loginId,
            DateTime? desde,
            DateTime? hasta,
            int? compraId,
            int? categoriaId,
            int? tipoId,
            int? inventarioId,
            bool? soloActivos,
            bool? soloInventario,
            int topN,
            string? q
        );

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

         public async Task<ReportePedidosOperativosViewModel> PedidosOperativos(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? pedidoEstatusId,
            int? clienteId,
            bool? soloAtrasados,
            int? produccionEstatusId,
            string? canal
        )
        {
            var vm = new ReportePedidosOperativosViewModel
            {
                Desde = (desde ?? DateTime.Today.AddDays(-14)).Date,
                Hasta = (hasta ?? DateTime.Today).Date,
                PedidoEstatusId = pedidoEstatusId,
                ClienteId = clienteId,
                SoloAtrasados = soloAtrasados ?? false,
                ProduccionEstatusId = produccionEstatusId,
                Canal = canal
            };

            using var connection = new SqlConnection(connectionString);

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesPedidosOperativos",
                new
                {
                    loginId = usuarioId,
                    desde = vm.Desde,
                    hasta = vm.Hasta,
                    pedidoEstatusId = (int?)vm.PedidoEstatusId,
                    clienteId = (int?)vm.ClienteId,
                    soloAtrasados = vm.SoloAtrasados,
                    produccionEstatusId = (int?)vm.ProduccionEstatusId,
                    canal = vm.Canal
                },
                commandType: CommandType.StoredProcedure
            );

            vm.Rows = (await multi.ReadAsync<ReportePedidoOperativoRow>()).ToList();
            vm.EstatusPedido = (await multi.ReadAsync<ReporteOpcionRow>()).ToList();
            vm.EstatusProduccion = (await multi.ReadAsync<ReporteOpcionRow>()).ToList();
            vm.Clientes = (await multi.ReadAsync<ReporteOpcionRow>()).ToList();

            return vm;
        }

        public async Task<ReporteCxcViewModel> CxcAging(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? pedidoId,
            bool soloVencidos,
            int? bucketId,
            string? metodo,
            decimal? minSaldo
        )
        {
            var vm = new ReporteCxcViewModel
            {
                Desde = (desde ?? DateTime.Today.AddDays(-30)).Date,
                Hasta = (hasta ?? DateTime.Today).Date,
                ClienteId = clienteId,
                PedidoId = pedidoId,
                SoloVencidos = soloVencidos,
                BucketId = bucketId,
                Metodo = metodo,
                MinSaldo = minSaldo
            };

            using var connection = new SqlConnection(connectionString);

            // Lookup clientes (para dropdown)
            var clientes = await connection.QueryAsync<LookupItem>(
                @"SELECT ClienteId AS Id, Nombre
                FROM dbo.TblClientes
                WHERE UsuarioId = @usuarioId AND EstaActivo = 1
                ORDER BY Nombre;",
                new { usuarioId }
            );
            vm.Clientes = clientes.ToList();

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesPagosCxcAging",
                new
                {
                    loginId = usuarioId,
                    desde = vm.Desde,
                    hasta = vm.Hasta,
                    clienteId = (int?)vm.ClienteId,
                    pedidoId = (int?)vm.PedidoId,
                    soloVencidos = vm.SoloVencidos,
                    bucketId = (int?)vm.BucketId,
                    metodo = vm.Metodo,
                    minSaldo = (decimal?)vm.MinSaldo
                },
                commandType: CommandType.StoredProcedure
            );

            vm.Totales = (await multi.ReadAsync<ReporteCxcTotales>()).FirstOrDefault() ?? new ReporteCxcTotales();
            vm.Buckets = (await multi.ReadAsync<ReporteCxcBucketRow>()).ToList();
            vm.Rows = (await multi.ReadAsync<ReporteCxcRow>()).ToList();

            return vm;
        }

        public async Task<ReporteCotizacionesSeguimientoViewModel> CotizacionesSeguimiento(
            int usuarioId,
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? cotizacionEstatusId,
            bool soloConvertidas,
            bool soloUltimaPorPedido,
            decimal? minMonto,
            string? q
        )
        {
            var vm = new ReporteCotizacionesSeguimientoViewModel
            {
                Desde = (desde ?? DateTime.Today.AddDays(-30)).Date,
                Hasta = (hasta ?? DateTime.Today).Date,
                ClienteId = clienteId,
                CotizacionEstatusId = cotizacionEstatusId,
                SoloConvertidas = soloConvertidas,
                SoloUltimaPorPedido = soloUltimaPorPedido,
                MinMonto = minMonto,
                Q = q
            };

            using var connection = new SqlConnection(connectionString);

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesCotizacionesSeguimiento",
                new
                {
                    loginId = usuarioId,
                    desde = vm.Desde,
                    hasta = vm.Hasta,
                    clienteId = (int?)vm.ClienteId,
                    cotizacionEstatusId = (int?)vm.CotizacionEstatusId,
                    soloConvertidas = vm.SoloConvertidas,
                    soloUltimaPorPedido = vm.SoloUltimaPorPedido,
                    minMonto = (decimal?)vm.MinMonto,
                    q = vm.Q
                },
                commandType: CommandType.StoredProcedure
            );

            vm.Totales = (await multi.ReadAsync<ReporteCotizacionesTotales>()).FirstOrDefault()
                        ?? new ReporteCotizacionesTotales();

            vm.PorEstatus = (await multi.ReadAsync<ReporteCotizacionEstatusResumenRow>()).ToList();
            vm.Rows = (await multi.ReadAsync<ReporteCotizacionSeguimientoRow>()).ToList();

            vm.Clientes = (await multi.ReadAsync<SimpleOption>()).ToList();
            vm.Estatus = (await multi.ReadAsync<SimpleOption>()).ToList();

            return vm;
        }

        public async Task<ReporteProduccionWipViewModel> GetProduccionWipDashboardAsync(
            int loginId,
            ReporteProduccionWipViewModel vm
        )
        {
            // defaults sanos para “tablero” (opcional)
            vm.Desde ??= DateTime.Today.AddDays(-14);
            vm.Hasta ??= DateTime.Today;

            using var con = new SqlConnection(connectionString);
            await con.OpenAsync();

            var args = new
            {
                loginId = loginId,

                desde = vm.Desde?.Date,
                hasta = vm.Hasta?.Date,

                clienteId = vm.ClienteId,
                pedidoId = vm.PedidoId,
                estatusId = vm.EstatusId,
                impresoraId = vm.ImpresoraId,

                soloWip = vm.SoloWip,
                soloAtrasados = vm.SoloAtrasados,
                sinImpresora = vm.SinImpresora,

                minDiasCola = vm.MinDiasCola,
                q = vm.Q
            };

            using var multi = await con.QueryMultipleAsync(
                "dbo.procReportesProduccionWipDashboard",
                args,
                commandType: CommandType.StoredProcedure
            );

            // 1) Totales
            vm.Totales = (await multi.ReadAsync<ReporteProduccionWipTotales>())
                .FirstOrDefault() ?? new ReporteProduccionWipTotales();

            // 2) WIP por estatus
            vm.WipPorEstatus = (await multi.ReadAsync<ReporteProduccionWipEstatusAgg>()).ToList();

            // 3) Items por impresora
            vm.PorImpresora = (await multi.ReadAsync<ReporteProduccionWipImpresoraAgg>()).ToList();

            // 4) Antigüedad (buckets)
            vm.PorAntiguedad = (await multi.ReadAsync<ReporteProduccionWipColaBucketAgg>()).ToList();

            // 5) Detalle
            vm.Detalle = (await multi.ReadAsync<ReporteProduccionWipDetalleRow>()).ToList();

            // 6) Dropdown estatus
            vm.CatEstatus = (await multi.ReadAsync<ReporteCatalogEstatusRow>()).ToList();

            // 7) Dropdown impresoras
            vm.CatImpresoras = (await multi.ReadAsync<ReporteCatalogImpresoraRow>()).ToList();

            // 8) Dropdown clientes
            vm.CatClientes = (await multi.ReadAsync<ReporteCatalogClienteRow>()).ToList();

            return vm;
        }

        public async Task<ReporteProduccionWipViewModel> ProduccionWipDashboard(
            int loginId,
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? pedidoId,
            int? estatusId,
            int? impresoraId,
            bool soloWip,
            bool soloAtrasados,
            bool sinImpresora,
            int? minDiasCola,
            string? q
        )
        {
            var vm = new ReporteProduccionWipViewModel
            {
                Desde = desde,
                Hasta = hasta,
                ClienteId = clienteId,
                PedidoId = pedidoId,
                EstatusId = estatusId,
                ImpresoraId = impresoraId,
                SoloWip = soloWip,
                SoloAtrasados = soloAtrasados,
                SinImpresora = sinImpresora,
                MinDiasCola = minDiasCola,
                Q = q
            };

            // defaults “tablero”
            vm.Desde ??= DateTime.Today.AddDays(-14);
            vm.Hasta ??= DateTime.Today;

            using var con = new SqlConnection(connectionString);
            await con.OpenAsync();

            var args = new
            {
                loginId,
                desde = vm.Desde?.Date,
                hasta = vm.Hasta?.Date,
                clienteId = vm.ClienteId,
                pedidoId = vm.PedidoId,
                estatusId = vm.EstatusId,
                impresoraId = vm.ImpresoraId,
                soloWip = vm.SoloWip,
                soloAtrasados = vm.SoloAtrasados,
                sinImpresora = vm.SinImpresora,
                minDiasCola = vm.MinDiasCola,
                q = string.IsNullOrWhiteSpace(vm.Q) ? null : vm.Q.Trim()
            };

            using var multi = await con.QueryMultipleAsync(
                "dbo.procReportesProduccionWipDashboard",
                args,
                commandType: CommandType.StoredProcedure
            );

            vm.Totales = (await multi.ReadAsync<ReporteProduccionWipTotales>()).FirstOrDefault()
                        ?? new ReporteProduccionWipTotales();

            vm.WipPorEstatus = (await multi.ReadAsync<ReporteProduccionWipEstatusAgg>()).ToList();
            vm.PorImpresora = (await multi.ReadAsync<ReporteProduccionWipImpresoraAgg>()).ToList();
            vm.PorAntiguedad = (await multi.ReadAsync<ReporteProduccionWipColaBucketAgg>()).ToList();
            vm.Detalle = (await multi.ReadAsync<ReporteProduccionWipDetalleRow>()).ToList();

            vm.CatEstatus = (await multi.ReadAsync<ReporteCatalogEstatusRow>()).ToList();
            vm.CatImpresoras = (await multi.ReadAsync<ReporteCatalogImpresoraRow>()).ToList();
            vm.CatClientes = (await multi.ReadAsync<ReporteCatalogClienteRow>()).ToList();

            return vm;
        }

        public async Task<ReporteProduccionUtilizacionViewModel> ProduccionUtilizacionImpresoras(
            int loginId,
            DateTime? desde,
            DateTime? hasta,
            int? impresoraId,
            bool incluirEnCurso,
            bool incluirSinImpresora,
            string? q
        )
        {
            using var connection = new SqlConnection(connectionString);

            var p = new DynamicParameters();
            p.Add("@loginId", loginId, DbType.Int32);
            p.Add("@desde", desde?.Date, DbType.Date);
            p.Add("@hasta", hasta?.Date, DbType.Date);
            p.Add("@impresoraId", impresoraId, DbType.Int32);
            p.Add("@incluirEnCurso", incluirEnCurso, DbType.Boolean);
            p.Add("@incluirSinImpresora", incluirSinImpresora, DbType.Boolean);
            p.Add("@q", q, DbType.String);

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesProduccionUtilizacionImpresoras",
                p,
                commandType: CommandType.StoredProcedure
            );

            var totales = await multi.ReadFirstOrDefaultAsync<ReporteProduccionUtilizacionTotalesDto>()
                        ?? new ReporteProduccionUtilizacionTotalesDto();

            var porImpresora = (await multi.ReadAsync<ReporteProduccionUtilizacionPorImpresoraDto>()).ToList();
            var detalle = (await multi.ReadAsync<ReporteProduccionUtilizacionDetalleDto>()).ToList();
            var catImpresoras = (await multi.ReadAsync<CatalogoImpresoraDto>()).ToList();

            return new ReporteProduccionUtilizacionViewModel
            {
                Desde = desde,
                Hasta = hasta,
                ImpresoraId = impresoraId,
                IncluirEnCurso = incluirEnCurso,
                IncluirSinImpresora = incluirSinImpresora,
                Q = q,

                Totales = totales,
                PorImpresora = porImpresora,
                Detalle = detalle,
                CatImpresoras = catImpresoras
            };
        }

         public async Task<ReporteInventarioConsumoMejoradoViewModel> InventarioConsumoMejorado(
            int loginId,
            DateTime? desde,
            DateTime? hasta,
            int? pedidoId,
            int? productoId,
            int? recetaId,
            int? inventarioId,
            string periodo,
            int topN,
            string? q
        )
        {
            using var connection = new SqlConnection(connectionString);

            var p = new
            {
                loginId,
                desde = (DateTime?)desde,
                hasta = (DateTime?)hasta,
                pedidoId,
                productoId,
                recetaId,
                inventarioId,
                periodo = periodo ?? "month",
                topN,
                q = q ?? ""
            };

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesInventarioConsumoMejorado",
                p,
                commandType: CommandType.StoredProcedure
            );

            var vm = new ReporteInventarioConsumoMejoradoViewModel
            {
                Desde = desde,
                Hasta = hasta,
                PedidoId = pedidoId,
                ProductoId = productoId,
                RecetaId = recetaId,
                InventarioId = inventarioId,
                Periodo = string.IsNullOrWhiteSpace(periodo) ? "month" : periodo,
                TopN = topN <= 0 ? 10 : topN,
                Q = q
            };

            vm.Totales = await multi.ReadSingleAsync<ReporteInventarioConsumoKpiDto>();
            vm.TopInsumos = (await multi.ReadAsync<ReporteInventarioConsumoTopInsumoDto>()).ToList();
            vm.PorProducto = (await multi.ReadAsync<ReporteInventarioConsumoPorProductoDto>()).ToList();
            vm.PorPedido = (await multi.ReadAsync<ReporteInventarioConsumoPorPedidoDto>()).ToList();
            vm.PorReceta = (await multi.ReadAsync<ReporteInventarioConsumoPorRecetaDto>()).ToList();
            vm.TopPorPeriodo = (await multi.ReadAsync<ReporteInventarioConsumoTopPeriodoDto>()).ToList();
            vm.Detalle = (await multi.ReadAsync<ReporteInventarioConsumoDetalleDto>()).ToList();

            vm.TarifasDetalle = (await multi.ReadAsync<ReporteInventarioConsumoTarifaDetalleDto>()).ToList();

            vm.CatProductos = (await multi.ReadAsync<CatalogoSimpleDto>()).ToList();
            vm.CatRecetas = (await multi.ReadAsync<CatalogoRecetaDto>()).ToList();
            vm.CatInsumos = (await multi.ReadAsync<CatalogoInsumoDto>()).ToList();

            // index para vista: "{ProduccionItemId}|{InventarioId}"
            vm.TarifasPorKey = vm.TarifasDetalle
                .GroupBy(x => $"{x.ProduccionItemId}|{x.InventarioId}")
                .ToDictionary(g => g.Key, g => g.OrderBy(t => t.TarifaOrden).ThenBy(t => t.TarifaId).ToList());

            return vm;
        }

        public async Task<ReporteComprasHistoricoVm> ComprasHistorico(
            int loginId,
            DateTime? desde,
            DateTime? hasta,
            int? compraId,
            int? categoriaId,
            int? tipoId,
            int? inventarioId,
            bool? soloActivos,
            bool? soloInventario,
            int topN,
            string? q
        )
        {
            using var connection = new SqlConnection(connectionString);

            var p = new
            {
                loginId,
                desde = (DateTime?)desde?.Date,
                hasta = (DateTime?)hasta?.Date,
                compraId,
                categoriaId,
                tipoId,
                inventarioId,
                soloActivos,
                soloInventario,
                topN = topN <= 0 ? 10 : topN,
                q = string.IsNullOrWhiteSpace(q) ? null : q.Trim()
            };

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procReportesComprasHistorico",
                p,
                commandType: CommandType.StoredProcedure
            );

            var vm = new ReporteComprasHistoricoVm
            {
                Desde = desde,
                Hasta = hasta,
                CompraId = compraId,
                CategoriaId = categoriaId,
                TipoId = tipoId,
                InventarioId = inventarioId,
                SoloActivos = soloActivos,
                SoloInventario = soloInventario,
                TopN = topN <= 0 ? 10 : topN,
                Q = q
            };

            vm.Kpis = (await multi.ReadAsync<ReporteComprasHistoricoKpiDto>()).FirstOrDefault() ?? new();
            vm.TopCategorias = (await multi.ReadAsync<ReporteComprasTopCategoriaDto>()).ToList();
            vm.TopTipos = (await multi.ReadAsync<ReporteComprasTopTipoDto>()).ToList();
            vm.TopInventarios = (await multi.ReadAsync<ReporteComprasTopInventarioDto>()).ToList();
            vm.Detalle = (await multi.ReadAsync<ReporteComprasHistoricoDetalleDto>()).ToList();

            vm.Categorias = (await multi.ReadAsync<CatalogoDto>()).ToList();
            vm.Tipos = (await multi.ReadAsync<CatalogoDto>()).ToList();
            vm.Inventarios = (await multi.ReadAsync<CatalogoDto>()).ToList();

            return vm;
        }

        

    }
}
