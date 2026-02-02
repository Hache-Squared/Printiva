using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;
using ManejoPresupuestos.Models;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioTarifas
    {
        Task<IEnumerable<TarifaConceptoDto>> ObtenerConceptos();
        Task<IEnumerable<TarifaListadoDto>> ObtenerPorInventario(int inventarioId, int loginId);
        Task<IEnumerable<TarifaListadoDto>> ObtenerPorImpresora(int impresoraId, int loginId);

        Task<TarifaCrearResultDto> Crear(TarifaCrearDto dto, int loginId);
        Task<ResultSimpleDto> Actualizar(TarifaActualizarDto dto, int loginId);
        Task<ResultSimpleDto> Eliminar(int tarifaId, int loginId);

        Task<IEnumerable<TarifaHistoricoDto>> ObtenerHistorico(int tarifaId, int loginId);
        Task<IEnumerable<TarifaSelectorInventarioDto>> SelectorInventarios(int loginId);
        Task<IEnumerable<TarifaSelectorImpresoraDto>> SelectorImpresoras(int loginId);
        Task<IEnumerable<TarifaAplicableDto>> ObtenerAplicables(string tarifaConceptoCodigo, int? impresoraId, int? inventarioId, int loginId);
    }

    public class RepositorioTarifas : IRepositorioTarifas
    {
        private sealed class ProcInventarioRow
        {
            public int InventarioId { get; set; }
            public decimal? Cantidad { get; set; }

            public string? InventarioMarca { get; set; }
            public string? InventarioTipo { get; set; }
            public string? InventarioNombre { get; set; }
            public string? InventarioNombreAbreviatura { get; set; }

            public string? InventarioColor { get; set; }
            public string? InventarioColorAbreviatura { get; set; }

            public string? InventarioUnidad { get; set; }
        }

        private readonly string connectionString;

        public RepositorioTarifas(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<TarifaConceptoDto>> ObtenerConceptos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<TarifaConceptoDto>(
                "dbo.procTarifasObtenerConceptos",
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<TarifaListadoDto>> ObtenerPorInventario(int inventarioId, int loginId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<TarifaListadoDto>(
                "dbo.procTarifasObtenerPorInventario",
                new { InventarioId = inventarioId, loginId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<TarifaListadoDto>> ObtenerPorImpresora(int impresoraId, int loginId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<TarifaListadoDto>(
                "dbo.procTarifasObtenerPorImpresora",
                new { ImpresoraId = impresoraId, loginId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<TarifaCrearResultDto> Crear(TarifaCrearDto dto, int loginId)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QuerySingleAsync<TarifaCrearResultDto>(
                "dbo.procTarifasSet",
                new
                {
                    TarifaConceptoCodigo = dto.TarifaConceptoCodigo,
                    Monto = dto.Monto,
                    Moneda = dto.Moneda,
                    Nombre = dto.Nombre,
                    Orden = dto.Orden,
                    ImpresoraId = dto.ImpresoraId,
                    InventarioId = dto.InventarioId,
                    loginId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultSimpleDto> Actualizar(TarifaActualizarDto dto, int loginId)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QuerySingleAsync<ResultSimpleDto>(
                "dbo.procTarifasActualizar",
                new
                {
                    TarifaId = dto.TarifaId,
                    Monto = dto.Monto,
                    Moneda = dto.Moneda,
                    Nombre = dto.Nombre,
                    Orden = dto.Orden,
                    loginId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultSimpleDto> Eliminar(int tarifaId, int loginId)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QuerySingleAsync<ResultSimpleDto>(
                "dbo.procTarifasEliminar",
                new { TarifaId = tarifaId, loginId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<TarifaHistoricoDto>> ObtenerHistorico(int tarifaId, int loginId)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QueryAsync<TarifaHistoricoDto>(
                "dbo.procTarifasObtenerHistoricoPorTarifaId",
                new { TarifaId = tarifaId, loginId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
        public async Task<IEnumerable<TarifaSelectorInventarioDto>> SelectorInventarios(int loginId)
        {
            using var connection = new SqlConnection(connectionString);

            // OJO: tu SP usa @ElementoObtenerId (0 = todos)
            var rows = await connection.QueryAsync<ProcInventarioRow>(
                "dbo.procObtenerInventarios",
                new { ElementoObtenerId = 0, loginId },
                commandType: System.Data.CommandType.StoredProcedure
            );

            // Proyección para UI (Display + Unidad)
            var result = rows.Select(r =>
            {
                var color = r.InventarioColor;

                var nombre = r.InventarioNombre;

                var display = $"{nombre} - {color} - {r.InventarioTipo} -  {r.InventarioMarca}"
                    .Replace("  ", " ")
                    .Trim();

                if (string.IsNullOrWhiteSpace(display))
                    display = $"{r.InventarioId}";

                return new TarifaSelectorInventarioDto
                {
                    InventarioId = r.InventarioId,
                    Cantidad = r.Cantidad,
                    Unidad = r.InventarioUnidad,
                    Display = $"{r.InventarioId} - {display}".Replace("  ", " ").Trim()
                };
            });

            return result;
        }

        public async Task<IEnumerable<TarifaSelectorImpresoraDto>> SelectorImpresoras(int loginId)
        {
            using var connection = new SqlConnection(connectionString);

            // FIX CLAVE:
            // - @ElementoObtenerId debe ser NULL para "todas"
            // - @SoloActivas = 1 (si quieres solo activas)
            var rows = await connection.QueryAsync<TarifaSelectorImpresoraDto>(
                "dbo.procObtenerImpresoras",
                new
                {
                    loginId,
                    ElementoObtenerId = (int?)null,
                    SoloActivas = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            return rows;
        }

        private sealed class TarifaAplicableRow
        {
            public string? result { get; set; }
            public string? message { get; set; }

            public int TarifaId { get; set; }
            public string TarifaNombre { get; set; } = "";
            public int TarifaOrden { get; set; }

            public int? ImpresoraId { get; set; }
            public int? InventarioId { get; set; }

            public decimal Monto { get; set; }
            public string Moneda { get; set; } = "MXN";
        }

        public async Task<IEnumerable<TarifaAplicableDto>> ObtenerAplicables(
            string tarifaConceptoCodigo,
            int? impresoraId,
            int? inventarioId,
            int loginId)
        {
            using var connection = new SqlConnection(connectionString);

            // Si tu SP mete result/message por fila, usa el “Row seguro” que ya te dejé antes.
            return await connection.QueryAsync<TarifaAplicableDto>(
                "dbo.procTarifasObtenerAplicables",
                new { TarifaConceptoCodigo = tarifaConceptoCodigo, ImpresoraId = impresoraId, InventarioId = inventarioId, loginId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

    }
    
}