// File: Servicios/RepositorioComprasV2.cs
using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioComprasV2
    {
        Task<IEnumerable<CompraV2>> ObtenerTodos(int usuarioId);
        Task<CompraV2?> ObtenerPorId(int usuarioId, int id);
        Task<int> Crear(int usuarioId, CompraV2 compra);
        Task Actualizar(int usuarioId, CompraV2 compra);
        Task Borrar(int usuarioId, int id);

        // Mantengo tu hook existente de transacciones (si lo ocupas)
        Task<int> CompraLogTransaccion(int usuarioId, CompraV2 compra, string accion = "CREAR");
    }

    public class RepositorioComprasV2 : IRepositorioComprasV2
    {
        private readonly string connectionString;

        public RepositorioComprasV2(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<CompraV2>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CompraV2>(
                "procObtenerComprasV2",
                new { elementoObtenerId = 0, loginId = usuarioId, soloActivos = 1 },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<CompraV2?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<CompraV2>(
                "procObtenerComprasV2",
                new { elementoObtenerId = id, loginId = usuarioId, soloActivos = 0 },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<int> Crear(int usuarioId, CompraV2 compra)
        {
            using var connection = new SqlConnection(connectionString);

            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraComprasV2",
                new
                {
                    elementoAlterarId = 0,
                    descripcion = compra.Descripcion,
                    compraTipoId = compra.CompraTipoId,
                    filamentoTipoId = compra.FilamentoTipoId,
                    compraCategoriaId = compra.CompraCategoriaId,

                    inventarioId = compra.InventarioId,
                    cantidad = compra.Cantidad,
                    costoUnitario = compra.CostoUnitario,
                    costoTotal = compra.CostoTotal,

                    fechaCreacion = compra.FechaCreacion,
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo crear la compra.");

            compra.CompraId = res.ElementoId;
            return res.ElementoId;
        }

        public async Task Actualizar(int usuarioId, CompraV2 compra)
        {
            using var connection = new SqlConnection(connectionString);

            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraComprasV2",
                new
                {
                    elementoAlterarId = compra.CompraId,
                    descripcion = compra.Descripcion,
                    compraTipoId = compra.CompraTipoId,
                    filamentoTipoId = compra.FilamentoTipoId,
                    compraCategoriaId = compra.CompraCategoriaId,

                    inventarioId = compra.InventarioId,
                    cantidad = compra.Cantidad,
                    costoUnitario = compra.CostoUnitario,
                    costoTotal = compra.CostoTotal,

                    fechaCreacion = compra.FechaCreacion,
                    loginId = usuarioId,
                    actualizar = 1,
                    borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo actualizar la compra.");
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);

            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraComprasV2",
                new
                {
                    elementoAlterarId = id,
                    descripcion = "Compra eliminada",
                    compraTipoId = 0,
                    filamentoTipoId = (int?)null,
                    compraCategoriaId = 0,

                    inventarioId = (int?)null,
                    cantidad = 0m,
                    costoUnitario = 0m,
                    costoTotal = 0m,

                    fechaCreacion = (DateTime?)null,
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo borrar la compra.");
        }

        public async Task<int> CompraLogTransaccion(int usuarioId, CompraV2 compra, string accion = "CREAR")
        {
            using var connection = new SqlConnection(connectionString);

            // Flags para el SP
            var crear = accion.Equals("CREAR", StringComparison.OrdinalIgnoreCase);
            var actualizar = accion.Equals("ACTUALIZAR", StringComparison.OrdinalIgnoreCase) || accion.Equals("EDITAR", StringComparison.OrdinalIgnoreCase);
            var borrar = accion.Equals("BORRAR", StringComparison.OrdinalIgnoreCase) || accion.Equals("DELETE", StringComparison.OrdinalIgnoreCase);

            var newId = await connection.QuerySingleAsync<int>(
                "dbo.procUpdateTransaccionesCompra",
                new
                {
                    CompraId = compra.CompraId,
                    UsuarioId = usuarioId,       // usa UsuarioId (el SP también acepta loginId si lo ocupas)
                    Descripcion = compra.Descripcion,
                    InventarioId = compra.InventarioId,
                    Cantidad = compra.Cantidad,
                    CostoUnitario = compra.CostoUnitario,
                    CostoTotal = compra.CostoTotal,
                    FechaCreacion = compra.FechaCreacion,

                    Crear = crear ? 1 : 0,
                    Actualizar = actualizar ? 1 : 0,
                    Borrar = borrar ? 1 : 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            return newId;
        }
    }
}